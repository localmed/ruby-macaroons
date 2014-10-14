require 'openssl'
require 'base64'

require 'rbnacl'

require 'macaroons/caveat'
require 'macaroons/utils'

module Macaroons
  class RawMacaroon
    PACKET_PREFIX_LENGTH = 4

    def initialize(key: nil, identifier: nil, location: nil, serialized: nil)
      if key.nil? && identifier.nil? && location.nil? && serialized.nil?
        raise ArgumentError, 'Must provide either (key, id, location), or serialized.'
      elsif (key.nil? || identifier.nil? || location.nil?) and serialized.nil?
        raise ArgumentError, 'Must provide all three: (key, id, location)'
      end

      @key = key
      @identifier = identifier
      @location = location
      @signature = create_initial_macaroon_signature(key, identifier) unless serialized
      @caveats = []
      deserialize(serialized) unless serialized.nil?
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
      verification_id = Base64.strict_encode64(ciphertext)
      caveat = Caveat.new(caveat_id, verification_id, caveat_location)
      @caveats << caveat
      sign_third_party_caveat(verification_id, caveat_id)
    end

    def serialize
      combined = packetize('location', @location)
      combined += packetize('identifier', @identifier)

      for caveat in @caveats
        combined += packetize('cid', caveat.caveat_id)

        if caveat.verification_id and caveat.caveat_location
          combined += packetize('vid', caveat.verification_id)
          combined += packetize('cl', caveat.caveat_location)
        end
      end

      combined += packetize(
        'signature',
        Utils.unhexlify(self.signature)
      )
      Base64.urlsafe_encode64(combined)
    end

    def prepare_for_request(macaroon)
      bound_macaroon = Marshal.load( Marshal.dump( macaroon ) )
      key = Utils.truncate_or_pad('0')
      hash1 = hmac(key, self.signature)
      hash2 = hmac(key, macaroon.signature)
      raw = bound_macaroon.instance_variable_get(:@raw_macaroon)
      raw.instance_variable_set(:@signature, hmac(key, hash1 + hash2))
      bound_macaroon
    end

    private

    def deserialize(serialized)
      @caveats = []

      decoded = Base64.urlsafe_decode64(serialized)

      index = 0

      while index < decoded.length
        packet_length = decoded[index..(index + PACKET_PREFIX_LENGTH - 1)].to_i(16)
        packet = decoded[index + PACKET_PREFIX_LENGTH..(index + packet_length - 2)]

        key, value = depacketize(packet)

        case key
        when 'location'
          @location = value
        when 'identifier'
          @identifier = value
        when 'cid'
          @caveats << Caveat.new(value)
        when 'vid'
          @caveats[-1].verification_id = value
        when 'cl'
          @caveats[-1].caveat_location = value
        when 'signature'
          @signature = value
        else
          raise KeyError, 'Invalid key in binary macaroon. Macaroon may be corrupted.'
        end

        index = index + packet_length
      end
    end

    def packetize(key, data)
      # The 2 covers the space and the newline
      packet_size = PACKET_PREFIX_LENGTH + 2 + key.length + data.length
      if packet_size > 65535
        # Due to packet structure, length of packet must be less than 0xFFFF
        raise ArgumentError, 'Data is too long for a binary packet.'
      end
      packet_size_hex = packet_size.to_s(16)
      header = packet_size_hex.to_s.rjust(4, '0')
      packet_content = "#{key} #{data}\n"
      packet = "#{header}#{packet_content}"
      packet
    end

    def depacketize(packet)
      key = packet.split(" ")[0]
      value = packet[key.length + 1..-1]
      [key, value]
    end

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
