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

  end
end
