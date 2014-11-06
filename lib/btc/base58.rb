# encoding: ASCII-8BIT
# base58.rb

module Btc
  class Base58
    class << self
      @@t = [
        '123456789A',
        'BCDEFGHJKL',
        'MNPQRSTUVW',
        'XYZabcdefg',
        'hijkmnopqr',
        'stuvwxyz'
      ]
      @@encoding_table = {}
      @@decoding_table = {}

      def decoding_table
        return @@decoding_table if !@@decoding_table.empty?       
        @@t.join.split('').each_with_index do |c, i|
          @@decoding_table[c] = i
        end
        @@decoding_table
      end

      def encoding_table
        return @@encoding_table if !@@encoding_table.empty?
        @@encoding_table = decoding_table.invert
      end

      # encode a binary array into a base58 string
      def encode(data)
        result = ""
        vlong = 0
        cdata = data.unpack('C*')
        cdata.each do |v|
          vlong = v + vlong*256
        end
        while vlong > 0 do 
          result = encoding_table[vlong % 58] + result
          vlong /= 58
        end
        while cdata.first == 0 do
          result = '1' + result
          cdata = cdata[1..-1]
        end
        result
      end

      # decode a base58 string into a binary array
      def decode(data_string)
        result = ""
        vlong = 0
        data_string.each_byte do |b| 
          v = decoding_table[b.chr]
          vlong = v + (58*vlong)
        end
        while vlong > 0 do
          result = (vlong % 256).chr + result
          vlong /= 256
        end
        while data_string[0] == '1' do
          result = "\x00" + result
          data_string = data_string[1..-1]
        end
        result
      end

      # create a base58check string from a char prefix and binary array
      def check( prefix, payload )
        a = prefix + payload
        rcheck = Digest::SHA256.digest( Digest::SHA256.digest( a ))
        encode( a + rcheck.byteslice(0,4) )
      end

      # decode a base58check and validate the checksum
      def check_decode( c, validate=true, prefix_size=1 )
        bc = decode c

        raise('invalid Btc::Base58check') if validate && c != check( bc.byteslice(0, prefix_size), bc.byteslice(prefix_size..-5) )
        
        [bc.byteslice(0, prefix_size), bc.byteslice(prefix_size..-5)]
      end
    end
  end
end





