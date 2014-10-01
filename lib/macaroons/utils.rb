module Macaroons
  module Utils

    def self.convert_to_bytes(string)
      string.encode('us-ascii') unless string.nil?
    end

    def self.hexlify(value)
      value.unpack('C*').map { |byte| '%02X' % byte }.join('')
    end

    def self.unhexlify(value)
      [value].pack('H*')
    end

  end
end
