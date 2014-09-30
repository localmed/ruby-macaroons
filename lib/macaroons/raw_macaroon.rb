require 'openssl'

module Macaroons
  class RawMacaroon
    def initialize(key, identifier, location)
      @key = key
      @identifier = identifier
      @location = location
      @signature = create_initial_macaroon_signature(key, identifier)
      @caveats = []
    end

    def key
      @key
    end

    def identifier
      @identifier
    end

    def location
      @location
    end

    def signature
      @signature
    end

    def caveats
      @caveats
    end

    def create_initial_macaroon_signature(key, identifier)
      derived_key = key_hmac(key='macaroons-key-generator', data=key)
      macaroon_hmac(derived_key, identifier)
    end

    def macaroon_hmac(key, data, digest=nil)
      digest = OpenSSL::Digest.new('sha256') if digest.nil?
      OpenSSL::HMAC.hexdigest(digest, key, data)
    end

    def key_hmac(key, data, digest=nil)
      digest = OpenSSL::Digest.new('sha256') if digest.nil?
      OpenSSL::HMAC.digest(digest, key, data)
    end

    private :create_initial_macaroon_signature, :macaroon_hmac, :key_hmac

  end
end
