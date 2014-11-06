# encoding: ASCII-8BIT

module Btc
  module Types
  # Encooders
    def to_uint8_a(val)
      to_uint_fixed_a(val, 1)
    end

    # 2 bytes, little endian
    def to_uint16_a(val)
      to_uint_fixed_a(val, 2)
    end

    # 4 bytes, little endian
    def to_uint32_a(val)
      to_uint_fixed_a(val, 4)
    end

    # 8 bytes, little endian
    def to_uint64_a(val)
      to_uint_fixed_a(val, 8)
    end

    def to_uint_fixed_a(val, size)
      # binary = []
      s = ""
      (0..size-1).each do
        byte = val % 256
        # binary.append byte.chr
        s += byte.chr
        val /= 256
      end
      # binary.join('')
      s
    end

    def to_varint(val)
      if val < 0xfd
        s = val.chr
      elsif val < 0xffff
        s = "\xfd" + to_uint16_a(val)
      elsif val < 0xffffffff
        s = "\xfe" + to_uint32_a(val)
      else
        s = "\xff" + to_uint64_a(val)
      end
      s
    end

    # Decoders, little endian
    def to_uint_n( s, n )
      num = 0
      (0..n-1).each do |i|
        num *= 256
        num += s.byteslice(n-1-i).ord
      end
      num
    end

    def to_uint8( s )
      to_uint_n( s, 1 )
    end

    def to_uint16( s )
      to_uint_n( s, 2 )
    end

    def to_uint32( s )
      to_uint_n( s, 4 )
    end

    def to_uint64( s )
      to_uint_n( s, 8 )
    end

    #parse a varint, returns the number and remainder of the string
    def to_vint( s )
      flag = s.byteslice(0)
      case flag
      when "\xff"
        v = to_uint64 s.byteslice 1,8
        size = 9
      when "\xfe"
        v = to_uint32 s.byteslice 1,4
        size = 5
      when "\xfd"
        v = to_uint16 s.byteslice 1,2
        size = 3
      else
        v = s.byteslice(0).ord
        size = 1
      end
      [v, s.byteslice(size..-1)]
    end

    # encode binary hash value to bytestring
    def binhash_to_a(h)
      h.reverse
    end

    # decode bytestring to binary hash 
    def to_binhash(s, size)
      [s.byteslice(0,size).reverse, s.byteslice(size..-1)]
    end

    #little endian - lsb to smallest address
    # 0x1234
    # a[0] = 0x34
    # a[1] = 0x12
    def to_lendian_a(val)
      binary = []
      while val > 0
        byte = val % 256
        binary.append byte.chr
        val /= 256
      end
      binary.join('')
    end

    #big endian msb to smallest address
    # 0x1234
    # a[0] = 0x12
    # a[1] = 0x34
    def to_bendian_a(val)
      binary = []
      while val > 0
        byte = val % 256
        binary.unshift byte.chr
        val /= 256
      end
      binary.join('')
    end
  end
end



