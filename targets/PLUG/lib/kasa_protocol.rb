# encoding: ascii-8bit

require 'cosmos/interfaces/protocols/protocol'

module Cosmos

  # Performs the TPLink SmartHome Protocol
  class KasaProtocol < Protocol

    def read_data(data)
      return super(data) if data.length <= 0
      return kasa_decode(data)
    end

    def write_data(data)
      return kasa_encode(data)
    end

    def kasa_encode(string)
      key = 171
      result = [string.length].pack("N")
      string.each_byte do |byte|
        a = key ^ byte
        key = a
        result << a
      end
      return result
    end

    def kasa_decode(string)
      key = 171
      result = ""
      string[4..-1].each_byte do |byte|
        a = key ^ byte
        key = byte
        result << [a].pack("C")
      end
      return result
    end

  end

end
