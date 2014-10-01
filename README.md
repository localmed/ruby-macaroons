# Macaroons

This is a Ruby implementation of Macaroons. It is currently under development.

## Installing

To use macaroons, you will need to install libsodium:
[libsodium](https://github.com/jedisct1/libsodium)

For OS X users, libsodium is available via homebrew and can be installed with:

    brew install libsodium

For FreeBSD users, libsodium is available both via pkgng and ports. To install a binary package:

    pkg install libsodium

To install from ports on FreeBSD, use your favorite ports front end (e.g. portmaster or portupgrade), or use make as follows:

    cd /usr/ports/security/libsodium; make install clean

### macaroons gem

Once you have libsodium installed, Add this line to your application's Gemfile:

    gem 'macaroons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install macaroons

Inside of your Ruby program do:
    require 'macaroons'

## Quickstart

    key => Very secret key used to sign the macaroon
    identifier => An identifier for the macaroon
    location => The location at which the macaroon is created

    # Construct a Macaroon.
    m = Macaroon.new(key, identifier, 'http://google.com')

    # Add a Caveat
    m.add_first_party_caveat('caveat_1')

## References

- [The Macaroon Paper](http://research.google.com/pubs/pub41892.html)
