require 'base64'

require 'macaroons/serializers/base'

module Macaroons
  class BinarySerializer < BaseSerializer
    PACKET_PREFIX_LENGTH = 4

    def serialize(macaroon)
      combined = packetize('location', macaroon.location)
      combined += packetize('identifier', macaroon.identifier)

      for caveat in macaroon.caveats
        combined += packetize('cid', caveat.caveat_id)

        if caveat.verification_id and caveat.caveat_location
          combined += packetize('vid', caveat.verification_id)
          combined += packetize('cl', caveat.caveat_location)
        end
      end

      combined += packetize(
        'signature',
        Utils.unhexlify(macaroon.signature)
      )
      Base64.urlsafe_encode64(combined)
    end

    def deserialize(serialized)
      caveats = []
      decoded = Base64.urlsafe_decode64(serialized)

      index = 0

      while index < decoded.length
        packet_length = decoded[index..(index + PACKET_PREFIX_LENGTH - 1)].to_i(16)
        stripped_packet = decoded[index + PACKET_PREFIX_LENGTH..(index + packet_length - 2)]

        key, value = depacketize(stripped_packet)

        case key
        when 'location'
          location = value
        when 'identifier'
          identifier = value
        when 'cid'
          caveats << Caveat.new(value)
        when 'vid'
          caveats[-1].verification_id = value
        when 'cl'
          caveats[-1].caveat_location = value
        when 'signature'
          signature = value
        else
          raise KeyError, 'Invalid key in binary macaroon. Macaroon may be corrupted.'
        end

        index = index + packet_length
      end
      macaroon = Macaroons::RawMacaroon.new(key: 'no_key', identifier: identifier, location: location)
      macaroon.caveats = caveats
      macaroon.signature = signature
      macaroon
    end

    private

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

  end
end
