require 'rbnacl'

require 'macaroons/errors'

module Macaroons
  class Verifier
    attr_accessor :predicates
    attr_accessor :callbacks

    def initialize
      @predicates = []
      @callbacks = []
    end

    def satisfy_exact(predicate)
      raise ArgumentError, 'Must provide predicate' unless predicate
      @predicates << predicate
    end

    def satisfy_general(callback = nil, &block)
      raise ArgumentError, 'Must provide callback or block' unless callback || block_given?
      callback = block if block_given?
      @callbacks << callback
    end

    def verify(macaroon: nil, key: nil, discharge_macaroons: nil)
      raise ArgumentError, 'Macaroon and Key required' if macaroon.nil? || key.nil?

      #calculated_signature = Macaroons::Macaroon.new(key: key, identifier: macaroon.identifier, location: macaroon.location).signature



      compare_macaroon = Macaroons::Macaroon.new(key: key, identifier: macaroon.identifier, location: macaroon.location)

      verify_caveats(macaroon, compare_macaroon, discharge_macaroons)

      raise SignatureMismatchError, 'Signatures do not match.' unless signatures_match(macaroon.signature, compare_macaroon.signature)

      return true
    end

    def verify_discharge(root: root, macaroon: macaroon, key: key, discharge_macaroons: [])
      compare_macaroon = Macaroon.new(
          location: macaroon.location,
          identifier: macaroon.identifier,
          key: key
      )
      p key
      p macaroon.identifier
      signature = Utils.hmac(key, macaroon.identifier)
      p signature
      raw = compare_macaroon.instance_variable_get(:@raw_macaroon)
      compare_macaroon.instance_variable_set(:@signature, Utils.unhexlify(signature))

      verify_caveats(macaroon, compare_macaroon, discharge_macaroons)

      compare_macaroon = root.prepare_for_request(compare_macaroon)

      p compare_macaroon.signature
      p Utils.unhexlify(compare_macaroon.signature)
      p macaroon.signature
      p Utils.unhexlify(macaroon.signature)

      raise SignatureMismatchError, 'Discharge macaroon not properly bound to root.' unless signatures_match(macaroon.signature, compare_macaroon.signature)

      return true
    end

    private

    def verify_caveats(macaroon, compare_macaroon, discharge_macaroons)
      for caveat in macaroon.caveats
        if caveat.first_party?
          caveat_met = verify_first_party_caveat(caveat, compare_macaroon)
        else
          caveat_met = verify_third_party_caveat(caveat, macaroon, compare_macaroon, discharge_macaroons)
        end
        raise CaveatUnsatisfiedError, "Caveat not met. Unable to satisfy: #{caveat.caveat_id}" unless caveat_met
      end
    end

    def verify_first_party_caveat(caveat, compare_macaroon)
      caveat_met = false
      if @predicates.include? caveat.caveat_id
        caveat_met = true
      else
        @callbacks.each do |callback|
          caveat_met = true if callback.call(caveat.caveat_id)
        end
      end
      compare_macaroon.add_first_party_caveat(caveat.caveat_id) if caveat_met

      return caveat_met
    end

    def verify_third_party_caveat(caveat, root_macaroon, compare_macaroon, discharge_macaroons)
      caveat_met = false

      caveat_macaroon = discharge_macaroons.find { |m| m.identifier == caveat.caveat_id }

      raise CaveatUnsatisfiedError("Caveat not met. No discharge macaroon found for identifier: #{caveat.caveat_id}") unless caveat_macaroon

      caveat_key = extract_caveat_key(compare_macaroon, caveat)

      caveat_macaroon_verifier = Verifier.new()
      caveat_macaroon_verifier.predicates = @predicates
      caveat_macaroon_verifier.callbacks = @callbacks

      caveat_met = caveat_macaroon_verifier.verify_discharge(
          root: root_macaroon,
          macaroon: caveat_macaroon,
          key: caveat_key,
          discharge_macaroons: discharge_macaroons
      )
      if caveat_met
        # Manually add caveat and update signature to avoid encryption
        new_caveat = Caveat.new(caveat.caveat_id, caveat.verification_id, caveat.caveat_location)
        compare_macaroon.caveats << new_caveat
        raw = compare_macaroon.instance_variable_get(:@raw_macaroon)
        raw.send(:sign_third_party_caveat, caveat.verification_id, caveat.caveat_id)
      end
      return caveat_met
    end

    def extract_caveat_key(compare_macaroon, caveat)
      key = Utils.truncate_or_pad(Utils.unhexlify(compare_macaroon.signature))
      box =  RbNaCl::SimpleBox.from_secret_key(key)
      decoded_vid = Base64.strict_decode64(caveat.verification_id)
      box.decrypt(decoded_vid)
    end


    def signatures_match(a, b)
      # Constant time compare, taken from Rack
      return false unless a.bytesize == b.bytesize

      l = a.unpack("C*")

      r, i = 0, -1
      b.each_byte { |v| r |= v ^ l[i+=1] }
      r == 0
    end

  end
end
