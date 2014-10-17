require 'macaroons/macaroons'
require 'macaroons/verifier'

module Macaroon
  class << self
    def new(location: location, identifier: identifier, key: key)
      Macaroons::Macaroon.new(location:location, identifier:identifier, key:key)
    end

    def from_binary(serialized)
      Macaroons::Macaroon.from_binary(serialized)
    end

    def from_json(serialized)
      Macaroons::Macaroon.from_json(serialized)
    end
  end

  class Verifier
    def self.new()
      Macaroons::Verifier.new()
    end
  end
end
