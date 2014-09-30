# Macaroons

This is a Ruby implementation of Macaroons. It is currently under development.

## Installing
Add this line to your application's Gemfile:

    gem 'macaroons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install macaroons

## Quickstart

    key => Very secret key used to sign the macaroon
    identifier => An identifier for the macaroon
    location => The location at which the macaroon is created

    # Construct a Macaroon.
    m = Macaroon.new(key, identifier, 'http://google.com')
