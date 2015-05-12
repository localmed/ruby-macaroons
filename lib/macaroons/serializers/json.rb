require 'multi_json'

module Macaroons
  class JsonSerializer

    def serialize(macaroon)
      caveats = macaroon.caveats.map! do |c|
        if c.first_party?
          c
        else
          Macaroons::Caveat.new(
            c.caveat_id,
            verification_id=Base64.strict_encode64(c.verification_id),
            caveat_location=c.caveat_location
          )
        end
      end
      serialized = {
        location: macaroon.location,
        identifier: macaroon.identifier,
        caveats: caveats.map(&:to_h),
        signature: macaroon.signature
      }
      MultiJson.dump(serialized)
    end

    def deserialize(serialized)
      deserialized = MultiJson.load(serialized)
      macaroon = Macaroons::RawMacaroon.new(key: 'no_key', identifier: deserialized['identifier'], location: deserialized['location'])
      deserialized['caveats'].each do |c|
        if c['vid']
          caveat = Macaroons::Caveat.new(c['cid'], Base64.strict_decode64(c['vid']), c['cl'])
        else
          caveat = Macaroons::Caveat.new(c['cid'], c['vid'], c['cl'])
        end
        macaroon.caveats << caveat
      end
      macaroon.signature = Utils.unhexlify(deserialized['signature'])
      macaroon
    end

  end
end
