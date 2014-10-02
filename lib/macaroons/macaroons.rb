require 'macaroons/raw_macaroon'

module Macaroons
  class Macaroon
    def initialize(key, identifier, location)
      @raw_macaroon = RawMacaroon.new(key, identifier, location)
    end

    def identifier
      @raw_macaroon.identifier
    end

    def location
      @raw_macaroon.location
    end

    def signature
      @raw_macaroon.signature
    end

    def caveats
      @raw_macaroon.caveats
    end

    def add_first_party_caveat(predicate)
      @raw_macaroon.add_first_party_caveat(predicate)
    end

    def first_party_caveats
      caveats.select(&:first_party?)
    end

    def add_third_party_caveat(caveat_key, caveat_id, caveat_location)
      @raw_macaroon.add_third_party_caveat(caveat_key, caveat_id, caveat_location)
    end

    def third_party_caveats
       caveats.select{|caveat| caveat.third_party?}
    end

  end
end
