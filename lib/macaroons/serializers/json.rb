require 'json'

module Macaroons
  class JsonSerializer

    def serialize(macaroon)
        serialized = {
          location: macaroon.location,
          identifier: macaroon.identifier,
          caveats: macaroon.caveats.map!(&:to_h),
          signature: macaroon.signature
        }
        return serialized.to_json
    end

    def deserialize(serialized)
      deserialized = JSON.parse(serialized)
      macaroon = Macaroons::RawMacaroon.new(key: 'no_key', identifier: deserialized['identifier'], location: deserialized['location'])
      deserialized['caveats'].each do |c|
        caveat = Macaroons::Caveat.new(c['cid'], c['vid'], c['cl'])
        macaroon.caveats << caveat
      end
      macaroon.signature = Utils.unhexlify(deserialized['signature'])
      macaroon
    end

  end
end
