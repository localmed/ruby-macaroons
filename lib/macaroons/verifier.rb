require 'rbnacl'

require 'macaroons/errors'

module Macaroons
  class Verifier
    attr_accessor :predicates
    attr_accessor :callbacks

    def initialize
      @predicates = []
      @callbacks = []
      @calculated_signature = nil
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
      key = Utils.generate_derived_key(key)
      verify_discharge(root: macaroon, macaroon: macaroon, key: key, discharge_macaroons:discharge_macaroons)
    end

    def verify_discharge(root: nil, macaroon: nil, key: nil, discharge_macaroons: [])
      @calculated_signature = Utils.hmac(key, macaroon.identifier)

      verify_caveats(macaroon, discharge_macaroons)

      if root != macaroon
        raw = root.instance_variable_get(:@raw_macaroon)
        @calculated_signature = raw.bind_signature(Utils.hexlify(@calculated_signature).downcase)
      end

      raise SignatureMismatchError, 'Signatures do not match.' unless signatures_match(Utils.unhexlify(macaroon.signature), @calculated_signature)

      return true
    end

    private

    def verify_caveats(macaroon, discharge_macaroons)
      for caveat in macaroon.caveats
        if caveat.first_party?
          caveat_met = verify_first_party_caveat(caveat)
        else
          caveat_met = verify_third_party_caveat(caveat, macaroon, discharge_macaroons)
        end
        raise CaveatUnsatisfiedError, "Caveat not met. Unable to satisfy: #{caveat.caveat_id}" unless caveat_met
      end
    end

    def verify_first_party_caveat(caveat)
      caveat_met = false
      if @predicates.include? caveat.caveat_id
        caveat_met = true
      else
        @callbacks.each do |callback|
          caveat_met = true if callback.call(caveat.caveat_id) == true
        end
      end
      @calculated_signature = Utils.sign_first_party_caveat(@calculated_signature, caveat.caveat_id) if caveat_met
      return caveat_met
    end

    def verify_third_party_caveat(caveat, root_macaroon, discharge_macaroons)
      caveat_met = false

      caveat_macaroon = discharge_macaroons.find { |m| m.identifier == caveat.caveat_id }
      raise CaveatUnsatisfiedError, "Caveat not met. No discharge macaroon found for identifier: #{caveat.caveat_id}" unless caveat_macaroon

      caveat_key = extract_caveat_key(@calculated_signature, caveat)
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
        @calculated_signature = Utils.sign_third_party_caveat(@calculated_signature, caveat.verification_id, caveat.caveat_id)
      end
      return caveat_met
    end

    def extract_caveat_key(signature, caveat)
      key = Utils.truncate_or_pad(signature)
      box = RbNaCl::SimpleBox.from_secret_key(key)
      decoded_vid = caveat.verification_id
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
