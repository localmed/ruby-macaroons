require 'openssl'

module Macaroons
  module Utils

    def self.convert_to_bytes(string)
      string.encode('us-ascii') unless string.nil?
    end

    def self.hexlify(value)
      value.unpack('C*').map { |byte| '%02X' % byte }.join('')
    end

    def self.unhexlify(value)
      [value].pack('H*')
    end

    def self.truncate_or_pad(string, size=nil)
      size = size.nil? ? 32 : size
      if string.length > size
        string[0, size]
      elsif string.length > size
        string + '\0'*(size-string.length)
      else
        string
      end
    end

    def self.hmac(key, data, digest=nil)
      digest = OpenSSL::Digest.new('sha256') if digest.nil?
      OpenSSL::HMAC.digest(digest, key, data)
    end

    def self.sign_first_party_caveat(signature, predicate)
      Utils.hmac(signature, predicate)
    end

    def self.sign_third_party_caveat(signature, verification_id, caveat_id)
      verification_id_hash = Utils.hmac(signature, verification_id)
      caveat_id_hash = Utils.hmac(signature, caveat_id)
      combined = verification_id_hash + caveat_id_hash
      Utils.hmac(signature, combined)
    end

    def self.generate_derived_key(key)
      Utils.hmac('macaroons-key-generator', key)
    end
  end
end
