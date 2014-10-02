require 'openssl'
require 'base64'

require 'rbnacl'

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
      sign_first_party_caveat(predicate)
    end

    def add_third_party_caveat(caveat_key, caveat_id, caveat_location)
      derived_caveat_key = Utils.truncate_or_pad(hmac('macaroons-key-generator', caveat_key))
      truncated_or_padded_signature = Utils.truncate_or_pad(@signature)
      box = RbNaCl::SimpleBox.from_secret_key(truncated_or_padded_signature)
      ciphertext = box.encrypt(derived_caveat_key)
      verification_id = Base64.encode64(ciphertext)
      caveat = Caveat.new(caveat_id, verification_id, caveat_location)
      @caveats << caveat
      sign_third_party_caveat(verification_id, caveat_id)
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

    def sign_first_party_caveat(predicate)
      @signature = hmac(@signature, predicate)
    end

    def sign_third_party_caveat(verification_id, caveat_id)
      verification_id_hash = hmac(@signature, verification_id)
      caveat_id_hash = hmac(@signature, caveat_id)
      combined = verification_id_hash + caveat_id_hash
      @signature = hmac(@signature, combined)
    end

  end
end
