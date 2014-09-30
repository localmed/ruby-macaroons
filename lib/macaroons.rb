require 'macaroons/macaroons'

module Macaroon
  class << self
    def new(location, identifier, key)
      Macaroons::Macaroon.new(location, identifier, key)
    end
  end
end
