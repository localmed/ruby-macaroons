require 'macaroons/macaroons'

module Macaroon
  class << self
    def new(location, identifier, key)
      Macaroons::Macaroon.new(location, identifier, key)
    end

    def from_binary(serialized)
      Macaroons::Macaroon.new(nil, nil, nil).from_binary(serialized)
    end
  end
end
