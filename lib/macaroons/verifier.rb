
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

    def verify(macaroon: nil, key: nil, discharge_macaroons: nil)
      raise ArgumentError, 'Macaroon and Key required' if macaroon.nil? || key.nil?

      compare_macaroon = Macaroons::Macaroon.new(key: key, identifier: macaroon.identifier, location: macaroon.location)

      verify_caveats(macaroon, compare_macaroon, discharge_macaroons)

      raise StandardError, 'Signatures do not match.' unless signatures_match(macaroon.signature, compare_macaroon.signature)

      return true
    end

    private

    def verify_caveats(macaroon, compare_macaroon, discharge_macaroons)
      for caveat in macaroon.caveats
        if caveat.first_party?
          caveatMet = verify_first_party_caveat(caveat, compare_macaroon)
        else
          caveatMet = verify_third_party_caveat(caveat, compare_macaroon, discharge_macaroons)
        end
        raise StandardError, "Caveat not met. Unable to satisfy: #{caveat.caveat_id}" unless caveatMet
      end
    end

    def verify_first_party_caveat(caveat, compare_macaroon)
      caveatMet = false
      if @predicates.include? caveat.caveat_id
        caveatMet = true
      else
        for callback in @callbacks
          caveatMet = true if callback(caveat.caveat_id)
        end
      end
      compare_macaroon.add_first_party_caveat(caveat.caveat_id) if caveatMet

      return caveatMet
    end

    def verify_third_party_caveat(caveat, compare_macaroon, discharge_macaroons)
      # TODO
      return true
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
