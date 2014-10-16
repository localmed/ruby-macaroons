require 'spec_helper'
require 'macaroons'
require 'macaroons/errors'

describe 'Macaroon' do
  context 'without caveats' do
    it 'should have correct signature' do
      m = Macaroon.new(
        'http://mybank/',
        'we used our secret key',
        'this is our super secret key; only we should know it'
      )
      expect(m.signature).to eql('e3d9e02908526c4c0039ae15114115d97fdd68bf2ba379b342aaf0f617d0552f')
    end
  end

  context 'with first party caveat' do
    it 'should have correct signature' do
      m = Macaroon.new(
        'http://mybank/',
        'we used our secret key',
        'this is our super secret key; only we should know it'
      )
      m.add_first_party_caveat('test = caveat')
      expect(m.signature).to eql('197bac7a044af33332865b9266e26d493bdd668a660e44d88ce1a998c23dbd67')
    end
  end

  context 'when serilizing as binary' do
    it 'should serialize properly' do
      m = Macaroon.new(
        'http://mybank/',
        'we used our secret key',
        'this is our super secret key; only we should know it'
      )
      m.add_first_party_caveat('test = caveat')
      expect(m.serialize()).to eql('MDAxY2xvY2F0aW9uIGh0dHA6Ly9teWJhbmsvCjAwMjZpZGVudGlmaWVyIHdlIHVzZWQgb3VyIHNlY3JldCBrZXkKMDAxNmNpZCB0ZXN0ID0gY2F2ZWF0CjAwMmZzaWduYXR1cmUgGXusegRK8zMyhluSZuJtSTvdZopmDkTYjOGpmMI9vWcK')
    end
  end

  context 'when deserializing binary' do
    it 'should deserialize properly' do
      m = Macaroon.from_binary(
        'MDAxY2xvY2F0aW9uIGh0dHA6Ly9teWJhbmsvCjAwMjZpZGVudGlmaWVyIHdlIHVzZWQgb3VyIHNlY3JldCBrZXkKMDAxNmNpZCB0ZXN0ID0gY2F2ZWF0CjAwMmZzaWduYXR1cmUgGXusegRK8zMyhluSZuJtSTvdZopmDkTYjOGpmMI9vWcK'
      )
      expect(m.signature).to eql('197bac7a044af33332865b9266e26d493bdd668a660e44d88ce1a998c23dbd67')
    end
  end

  context 'when serilizing as json' do
    it 'should serialize properly' do
      m = Macaroon.new(
        'http://mybank/',
        'we used our secret key',
        'this is our super secret key; only we should know it'
      )
      m.add_first_party_caveat('test = caveat')
      expect(m.serialize_json()).to eql('{"location":"http://mybank/","identifier":"we used our secret key","caveats":[{"cid":"test = caveat","vid":null,"cl":null}],"signature":"197bac7a044af33332865b9266e26d493bdd668a660e44d88ce1a998c23dbd67"}')
    end
  end

  context 'when deserializing json' do
    it 'should deserialize properly' do
      m = Macaroon.from_json(
        '{"location":"http://mybank/","identifier":"we used our secret key","caveats":[{"cid":"test = caveat","vid":null,"cl":null}],"signature":"197bac7a044af33332865b9266e26d493bdd668a660e44d88ce1a998c23dbd67"}'
      )
      expect(m.signature).to eql('197bac7a044af33332865b9266e26d493bdd668a660e44d88ce1a998c23dbd67')
    end
  end

  context 'when serializing/deserializing binary with first and third caveats' do
    it 'should serialize/deserialize properly' do
      m = Macaroon.new(
          'http://mybank/',
          'we used our other secret key',
          'this is a different super-secret key; never use the same secret twice'
      )
      m.add_first_party_caveat('account = 3735928559')
      caveat_key = '4; guaranteed random by a fair toss of the dice'
      identifier = 'this was how we remind auth of key/pred'
      m.add_third_party_caveat(caveat_key, identifier, 'http://auth.mybank/')
      n = Macaroon.from_binary(m.serialize())
      expect(m.signature).to eql(n.signature)
    end
  end

  context 'when serializing/deserializing json with first and third caveats' do
    it 'should serialize/deserialize properly' do
      m = Macaroon.new(
          'http://mybank/',
          'we used our other secret key',
          'this is a different super-secret key; never use the same secret twice'
      )
      m.add_first_party_caveat('account = 3735928559')
      caveat_key = '4; guaranteed random by a fair toss of the dice'
      identifier = 'this was how we remind auth of key/pred'
      m.add_third_party_caveat(caveat_key, identifier, 'http://auth.mybank/')
      n = Macaroon.from_json(m.serialize_json())
      expect(m.signature).to eql(n.signature)
    end
  end

  context 'when perparing a macaroon for request' do
    it 'should bind the signature to the root' do
      m = Macaroon.new(
        'http://mybank/',
        'we used our other secret key',
        'this is a different super-secret key; never use the same secret twice'
      )
      m.add_first_party_caveat('account = 3735928559')
      caveat_key = '4; guaranteed random by a fair toss of the dice'
      identifier = 'this was how we remind auth of key/pred'
      m.add_third_party_caveat(caveat_key, identifier, 'http://auth.mybank/')

      discharge = Macaroon.new(
        'http://auth.mybank/',
        identifier,
        caveat_key
      )
      discharge.add_first_party_caveat('time < 2015-01-01T00:00')
      protected_discharge = m.prepare_for_request(discharge)

      expect(discharge.signature).not_to eql(protected_discharge.signature)
    end
  end
end

describe 'Verifier' do
  context 'verifying first party exact caveats' do
    before(:all) do
      @m = Macaroon.new(
        'http://mybank/',
        'we used our secret key',
        'this is our super secret key; only we should know it'
      )
      @m.add_first_party_caveat('test = caveat')
    end

    context 'all caveats met' do
      it 'should verify the macaroon' do
        v = Macaroon::Verifier.new()
        v.satisfy_exact('test = caveat')
        verified = v.verify(
            macaroon: @m,
            key: 'this is our super secret key; only we should know it'
        )
        expect(verified).to be(true)
      end
    end
    context 'not all caveats met' do
      it 'should raise an error' do
        v = Macaroon::Verifier.new()
        expect {
          v.verify(
            macaroon: @m,
            key: 'this is our super secret key; only we should know it'
          )
        }.to raise_error
      end
    end
  end

  context 'verifying first party general caveats' do
    before(:all) do
      @m = Macaroon.new(
        'http://mybank/',
        'we used our secret key',
        'this is our super secret key; only we should know it'
      )
      @m.add_first_party_caveat('general caveat')
    end

    context 'all caveats met' do
      it 'should verify the macaroon' do
        v = Macaroon::Verifier.new()
        v.satisfy_general { |predicate| predicate == 'general caveat' }
        verified = v.verify(
            macaroon: @m,
            key: 'this is our super secret key; only we should know it'
        )
        expect(verified).to be(true)
      end
    end
    context 'not all caveats met' do
      it 'should raise an error' do
        v = Macaroon::Verifier.new()
        v.satisfy_general { |predicate| predicate == 'unmet' }
        expect {
          v.verify(
            macaroon: @m,
            key: 'this is our super secret key; only we should know it'
          )
        }.to raise_error
      end
    end
  end

  context 'verifying third party caveats' do
    before(:all) do
      @m = Macaroon.new(
        'http://mybank/',
        'we used our other secret key',
        'this is a different super-secret key; never use the same secret twice'
      )
      @m.add_first_party_caveat('account = 3735928559')
      caveat_key = '4; guaranteed random by a fair toss of the dice'
      identifier = 'this was how we remind auth of key/pred'
      @m.add_third_party_caveat(caveat_key, identifier, 'http://auth.mybank/')

      discharge = Macaroon.new(
        'http://auth.mybank/',
        identifier,
        caveat_key
      )
      discharge.add_first_party_caveat('time < 2015-01-01T00:00')
      @protected_discharge = @m.prepare_for_request(discharge)
    end

    context 'all caveats met and discharges provided' do
      it 'should verify the macaroon' do
        v = Macaroon::Verifier.new()
        v.satisfy_exact('account = 3735928559')
        v.satisfy_exact('time < 2015-01-01T00:00')
        verified = v.verify(
            macaroon: @m,
            key: 'this is a different super-secret key; never use the same secret twice',
            discharge_macaroons: [@protected_discharge]
        )
      end
    end

    context 'not all caveats met' do
      it 'should raise an error' do
        v = Macaroon::Verifier.new()
        v.satisfy_exact('account = 3735928559')
        expect {
          v.verify(
            macaroon: @m,
            key: 'this is a different super-secret key; never use the same secret twice',
            discharge_macaroons: [@protected_discharge]
          )
        }.to raise_error
      end
    end

    context 'not all discharges provided' do
      it 'should raise an error' do
        v = Macaroon::Verifier.new()
        v.satisfy_exact('account = 3735928559')
        v.satisfy_exact('time < 2015-01-01T00:00')
        expect {
          v.verify(
            macaroon: @m,
            key: 'this is a different super-secret key; never use the same secret twice',
            discharge_macaroons: []
          )
        }.to raise_error
      end
    end
  end

end
