require 'macaroons/macaroons'

module Macaroon
  class << self
    def new(location, identifier, key)
      Macaroons::Macaroon.new(location:location, identifier:identifier, key:key)
    end

    def from_binary(serialized)
      Macaroons::Macaroon.from_binary(serialized)
    end
  end
end
