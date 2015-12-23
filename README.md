# Macaroons
[![Build Status](https://travis-ci.org/localmed/ruby-macaroons.svg?branch=master)](https://travis-ci.org/localmed/ruby-macaroons)
[![Coverage Status](https://img.shields.io/coveralls/localmed/ruby-macaroons.svg)](https://coveralls.io/r/localmed/ruby-macaroons?branch=master)
[![Gem Version](https://badge.fury.io/rb/macaroons.svg)](http://badge.fury.io/rb/macaroons)

This is a Ruby implementation of macaroons. The implementation is stable but could still be subject to change, pending any standardization attempts around macaroons.

## What is a Macaroon? 
Macaroons, like cookies, are a form of bearer credential. Unlike opaque tokens, macaroons embed *caveats* that define specific authorization requirements for the *target service*, the service that issued the root macaroon and which is capable of verifying the integrity of macaroons it recieves. 

Macaroons allow for delegation and attenuation of authorization. They are simple and fast to verify, and decouple authorization policy from the enforcement of that policy.

Simple examples are outlined below. For more in-depth examples check out the [functional tests](https://github.com/localmed/ruby-macaroons/blob/master/spec/integration_spec.rb) and [references](#references).

## Installing

The macaroon implementation is pure Ruby, but relies on [rbnacl-libsodium](https://github.com/cryptosphere/rbnacl-libsodium) to provide strong cryptographic primitives.

Install with: 

```
gem install macaroons
```

And then import it into your Ruby program:

```ruby
require 'macaroons'
```

## Quickstart

```ruby
key => Very secret key used to sign the macaroon
identifier => An identifier, to remind you which key was used to sign the macaroon
location => The location at which the macaroon is created

# Construct a Macaroon.
m = Macaroon.new(key: key, identifier: identifier, location: 'http://foo.com')

# Add first party caveat
m.add_first_party_caveat('caveat_1')

# List all first party caveats
m.first_party_caveats

# Add third party caveat
m.add_third_party_caveat('caveat_key', 'caveat_id', 'http://foo.com')

# List all third party caveats
m.third_party_caveats
```

## Example with first- and third-party caveats

```ruby

# Create macaroon. Sign with a key and identifier (a way to remember which key was used)
m = Macaroon.new(
  location: 'http://mybank/',
  identifier: 'we used our other secret key',
  key: 'this is a different super-secret key; never use the same secret twice'
)

# Add a first party caveat
m.add_first_party_caveat('account = 3735928559')

# Add a third party caveat
caveat_key = '4; guaranteed random by a fair toss of the dice'
identifier = 'this was how we remind auth of key/pred'
m.add_third_party_caveat(caveat_key, identifier, 'http://auth.mybank/')

# User collects a discharge macaroon (likely from a separate service), that proves the claims in the third-party caveat and which may add additional caveats of its own
discharge = Macaroon.new(
  location: 'http://auth.mybank/',
  identifier: identifier,
  key: caveat_key
)
discharge.add_first_party_caveat('time < 2015-01-01T00:00')

# discharge macaroons are bound to the root macaroon so they cannot be reused
protected_discharge = m.prepare_for_request(discharge)

# The user sends their macaroon along with their discharge macaroons, and we verify them
v = Macaroon::Verifier.new()
v.satisfy_exact('account = 3735928559')
v.satisfy_exact('time < 2015-01-01T00:00')
verified = v.verify(
    macaroon: m,
    key: 'this is a different super-secret key; never use the same secret twice',
    discharge_macaroons: [protected_discharge]
)
```

## More Macaroons

[PyMacaroons](https://github.com/ecordell/pymacaroons) is available for Python. PyMacaroons and Ruby-Macaroons are completely compatible (they can be used interchangibly within the same target service).

The [libmacaroons library](https://github.com/rescrv/libmacaroons) comes with Python and Go bindings.
 
PyMacaroons, libmacaroons, and Ruby-Macaroons all use the same underlying cryptographic library (libsodium).

## References

- [The Macaroon Paper](http://research.google.com/pubs/pub41892.html)
- [Mozilla Macaroon Tech Talk](https://air.mozilla.org/macaroons-cookies-with-contextual-caveats-for-decentralized-authorization-in-the-cloud/)
- [libmacaroons](https://github.com/rescrv/libmacaroons)
- [PyMacaroons](https://github.com/ecordell/pymacaroons)
- [rbnacl-libsodium](https://github.com/cryptosphere/rbnacl-libsodium) 
