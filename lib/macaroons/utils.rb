module Macaroons
  module Utils

    def self.convert_to_bytes(string)
      string.encode('us-ascii') unless string.nil?
    end

  end
end
