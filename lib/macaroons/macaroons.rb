require 'forwardable'

require 'macaroons/raw_macaroon'

module Macaroons
  class Macaroon
    extend Forwardable

    def initialize(key: nil, identifier: nil, location: nil, raw_macaroon: nil)
      @raw_macaroon = raw_macaroon || RawMacaroon.new(key: key, identifier: identifier, location: location)
    end

    def_delegators :@raw_macaroon, :identifier, :location, :signature, :caveats,
      :serialize, :serialize_json, :add_first_party_caveat, :add_third_party_caveat, :prepare_for_request

    def self.from_binary(serialized)
      raw_macaroon = RawMacaroon.from_binary(serialized: serialized)
      macaroon = Macaroons::Macaroon.new(raw_macaroon: raw_macaroon)
    end

    def self.from_json(serialized)
      raw_macaroon = RawMacaroon.from_json(serialized: serialized)
      macaroon = Macaroons::Macaroon.new(raw_macaroon: raw_macaroon)
    end

    def first_party_caveats
      caveats.select(&:first_party?)
    end

    def third_party_caveats
      caveats.select(&:third_party?)
    end

  end
end
