require 'base64'

require 'rbnacl'

require 'macaroons/caveat'
require 'macaroons/utils'
require 'macaroons/serializers/binary'

module Macaroons
  class RawMacaroon

    def initialize(key: nil, identifier: nil, location: nil)
      if key.nil? || identifier.nil? || location.nil?
        raise ArgumentError, 'Must provide all three: (key, id, location)'
      end

      @key = key
      @identifier = identifier
      @location = location
      @signature = create_initial_macaroon_signature(key, identifier)
      @caveats = []
    end

    def self.from_binary(serialized: serialized)
      Macaroons::BinarySerializer.new().deserialize(serialized)
    end

    attr_reader :identifier
    attr_reader :key
    attr_reader :location
    attr_accessor :caveats
    attr_accessor :signature

    def signature
      Utils.hexlify(@signature).downcase
    end

    def add_first_party_caveat(predicate)
      caveat = Caveat.new(predicate)
      @caveats << caveat
      @signature = Utils.sign_first_party_caveat(@signature, predicate)
    end

    def add_third_party_caveat(caveat_key, caveat_id, caveat_location)
      derived_caveat_key = Utils.truncate_or_pad(Utils.hmac('macaroons-key-generator', caveat_key))
      truncated_or_padded_signature = Utils.truncate_or_pad(@signature)
      box = RbNaCl::SimpleBox.from_secret_key(truncated_or_padded_signature)
      ciphertext = box.encrypt(derived_caveat_key)
      verification_id = Base64.strict_encode64(ciphertext)
      caveat = Caveat.new(caveat_id, verification_id, caveat_location)
      @caveats << caveat
      @signature = Utils.sign_third_party_caveat(@signature, verification_id, caveat_id)
    end

    def serialize
      Macaroons::BinarySerializer.new().serialize(self)
    end

    def prepare_for_request(macaroon)
      bound_macaroon = Marshal.load( Marshal.dump( macaroon ) )
      raw = bound_macaroon.instance_variable_get(:@raw_macaroon)
      raw.signature = bind_signature(macaroon.signature)
      bound_macaroon
    end

    def bind_signature(signature)
      key = Utils.truncate_or_pad('0')
      hash1 = Utils.hmac(key, Utils.unhexlify(self.signature))
      hash2 = Utils.hmac(key, Utils.unhexlify(signature))
      Utils.hmac(key, hash1 + hash2)
    end

    private

    def create_initial_macaroon_signature(key, identifier)
      derived_key = Utils.generate_derived_key(key)
      Utils.hmac(derived_key, identifier)
    end

  end
end
