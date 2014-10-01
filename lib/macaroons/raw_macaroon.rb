require 'openssl'
require 'macaroons/caveat'
require 'macaroons/utils'

module Macaroons
  class RawMacaroon
    def initialize(key, identifier, location=nil)
      @key = key
      @identifier = identifier
      @location = location
      @signature = create_initial_macaroon_signature(key, identifier)
      @caveats = []
    end

    attr_reader :identifier
    attr_reader :key
    attr_reader :location
    attr_reader :caveats

    def signature
      Utils.hexlify(@signature).downcase
    end

    def add_first_party_caveat(predicate)
      caveat = Caveat.new(predicate)
      @caveats << caveat
      @signature = hmac(@signature, predicate)
    end

    private

    def create_initial_macaroon_signature(key, identifier)
      derived_key = hmac('macaroons-key-generator', key)
      hmac(derived_key, identifier)
    end

    def hmac(key, data, digest=nil)
      digest = OpenSSL::Digest.new('sha256') if digest.nil?
      OpenSSL::HMAC.digest(digest, key, data)
    end

  end
end
