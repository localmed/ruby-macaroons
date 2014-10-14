require 'macaroons/raw_macaroon'

module Macaroons
  class Macaroon
    def initialize(key: nil, identifier: nil, location: nil, raw_macaroon: nil)
      @raw_macaroon = raw_macaroon || RawMacaroon.new(key: key, identifier: identifier, location: location)
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

    def self.from_binary(serialized)
      raw_macaroon = RawMacaroon.new(serialized: serialized)
      macaroon = Macaroons::Macaroon.new(raw_macaroon: raw_macaroon)
    end

    def serialize
      @raw_macaroon.serialize()
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
      caveats.select(&:third_party?)
    end

    def prepare_for_request(macaroon)
      @raw_macaroon.prepare_for_request(macaroon)
    end
  end
end
