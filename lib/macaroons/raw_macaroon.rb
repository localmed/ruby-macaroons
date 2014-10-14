require 'openssl'
require 'base64'

require 'rbnacl'

require 'macaroons/caveat'
require 'macaroons/utils'

module Macaroons
  class RawMacaroon
    PACKET_PREFIX_LENGTH = 4

    def initialize(key, identifier, location=nil, serialized=nil)
      @key = key
      @identifier = identifier
      @location = location
      @signature = create_initial_macaroon_signature(key, identifier)
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
      verification_id = Base64.encode64(ciphertext)
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

    private

    def deserialize(serialized)
      @caveats = []

      decoded = Base64.urlsafe_decode64(serialized)

      index = 0

      while index < decoded.length
        packet_length = decoded[index..(index + PACKET_PREFIX_LENGTH - 1)].to_i(16)
        packet = decoded[index..(index + packet_length)]

        start_index = index + PACKET_PREFIX_LENGTH
        end_index = index + packet_length - 2
        if packet[PACKET_PREFIX_LENGTH..-1].start_with?('location')
          @location = decoded[start_index + 'location '.length..end_index]
        end

        if packet[PACKET_PREFIX_LENGTH..-1].start_with?('identifier')
          @identifier = decoded[start_index + 'identifier '.length..end_index]
        end

        if packet[PACKET_PREFIX_LENGTH..-1].start_with?('cid')
          cid = decoded[start_index + 'cid '.length..end_index]
          @caveats << Caveat.new(cid)
        end

        if packet[PACKET_PREFIX_LENGTH..-1].start_with?('vid')
          vid = decoded[start_index + 'vid '.length..end_index]
          @caveats[-1].verification_id = vid
        end

        if packet[PACKET_PREFIX_LENGTH..-1].start_with?('cl')
          cl = decoded[start_index + 'cl '.length..end_index]
          @caveats[-1].caveat_location = cl
        end

        if packet[PACKET_PREFIX_LENGTH..-1].start_with?('signature')
          @signature = decoded[start_index + 'signature '.length..end_index]
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

    def create_initial_macaroon_signature(key, identifier)
      return nil if key.nil? or identifier.nil?
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
