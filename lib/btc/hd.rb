# hd.rb
#
# BIP0032 - https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
#
#
#
# 
# require 'openssl_extensions'

class Btc::Hd
  class Address
    include OpenSSL

    attr_accessor :master, :key

    GROUP_NAME = 'secp256k1'

    def initialize
      self.key = PKey::EC.new(GROUP_NAME)
      self.key.generate_key
    end

    # k is a PKey::EC
    def privkey(k)
      [k.private_key.to_s(16)].pack('H*')
    end

    # k is a PKey::EC
    def pubkey(k)
      public_key_string = k.public_key.to_bn.to_s(16)
      prefix = public_key_string.byteslice(-1).to_i(16) % 2 == 0 ? "02" : "03"
      public_key_string = prefix + public_key_string.byteslice(2..65)

      [ public_key_string ].pack('H*')
    end
  end

  class ExtendedKey
    include Btc::Types

    attr_accessor :keytype, :depth, :child_number, :chain_code, :key, :parent_key, :parent_fingerprint

    GROUP_NAME = 'secp256k1'

    NETWORK_TYPE_MAINNET = 'mainnet'
    NETWORK_TYPE_TESTNET = 'testnet'

    class << self
      @@network_type = NETWORK_TYPE_MAINNET

      def network_type
        @@network_type
      end

      def network_type=(nt)
        @@network_type = nt
      end

      def valid?(b58check)
        r = Btc::Base58.decode b58check
        b58check == Btc::Base58.check( r.byteslice(0), r.byteslice(1,20) )
      end
    end

   # 4 byte: version bytes (mainnet: 0x0488B21E public, 0x0488ADE4 private; testnet: 0x043587CF public, 0x04358394 private)
    MAINNET_PUBLIC_VERSION  = ["0488B21E"].pack('H*')
    MAINNET_PRIVATE_VERSION = ["0488ADE4"].pack('H*')
    TESTNET_PUBLIC_VERSION  = ["043587CF"].pack('H*')
    TESTNET_PRIVATE_VERSION = ["04358394"].pack('H*')

    PRIVATE_KEY = 'private_key'
    PUBLIC_KEY = 'public_key'


# Generate a seed byte sequence S of a chosen length (between 128 and 512 bits; 256 bits is advised) from a (P)RNG.
# Calculate I = HMAC-SHA512(Key = "Bitcoin seed", Data = S)
# Split I into two 32-byte sequences, IL and IR.
# Use parse256(IL) as master secret key, and IR as master chain code.
    def master(m)
      iv = OpenSSL::HMAC.digest('sha512', "Bitcoin seed", m )
      self.key = iv.byteslice(0..31)
      self.chain_code = iv.byteslice(32..63)
      self.keytype = PRIVATE_KEY
      self.depth = 0
      self.child_number = 0
      self.parent_key = nil
    end

    # Derive the i-th private key from the parent private key
    # key is the parent private key (byte array) 
    # chain_code is the parent chain code (byte array)
    # i is the desired index (integer)
    # returns a new private Btc::Hd::ExtendedKey
    def ckd_private(i)
      kpar = key
      cpar = chain_code
      if i >= 2**31
        # I = HMAC-SHA512(Key = cpar, Data = 0x00 || ser256(kpar) || ser32(i))
        hashable_key = ["00"].pack('H*') + kpar + to_uint32_a(i).reverse
        iv = OpenSSL::HMAC.digest('sha512', cpar, hashable_key )
      else
        # I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i))
        newk = OpenSSL::PKey::EC.new(GROUP_NAME)
        newk.generate_key

        newk.private_key = OpenSSL::BN.new( kpar.unpack('H*').first, 16 ) #kpar needs to be a bn
        
        newk.public_key = newk.group.generator.mul(newk.private_key)

        hashable_key = compress(newk.public_key) + to_uint32_a(i).reverse
        iv = OpenSSL::HMAC.digest('sha512', cpar, hashable_key )
      end

      ivL = iv.byteslice(0..31)
      ivR = iv.byteslice(32..63)

      n = OpenSSL::PKey::EC.new(GROUP_NAME).group.order

      k = (OpenSSL::BN.new( ivL.unpack('H*').first, 16) + OpenSSL::BN.new( kpar.unpack('H*').first, 16)) % n
      k = [k.to_s(16)].pack('H*')
      ci = ivR

      new_ek = Btc::Hd::ExtendedKey.new
      new_ek.parent_key = self
      new_ek.keytype = self.keytype
      new_ek.child_number = i
      new_ek.key = k
      new_ek.depth = depth + 1
      new_ek.chain_code = ci
      new_ek
    end

    def ckd_public(i=nil)
      if i.nil?
        new_public_key = Btc::Hd::ExtendedKey.new
        new_public_key.keytype = PUBLIC_KEY
        new_public_key.depth = depth
        new_public_key.parent_key = parent_key
        new_public_key.child_number = child_number
        new_public_key.chain_code = chain_code
        new_public_key.key = public_key
        new_public_key
      elsif keytype == PRIVATE_KEY
        k = ckd_private(i)
        k.ckd_public
      elsif keytype == PUBLIC_KEY
        # If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(Kpar) || ser32(i)).
        kpar = key
        cpar = chain_code
        if i >= 2**31
          raise "cannot generate hardened public key from public key"
        else
          # I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i))
          hashable_key = compress(key) + to_uint32_a(i).reverse
          iv = OpenSSL::HMAC.digest('sha512', cpar, hashable_key )
        end

        ivL = iv.byteslice(0..31)
        ivR = iv.byteslice(32..63)

        newk = OpenSSL::PKey::EC.new(GROUP_NAME)

        newk.generate_key
        newk.private_key = OpenSSL::BN.new( ivL.unpack('H*').first, 16 )
        newpoint = newk.group.generator.mul(newk.private_key)
        k = newpoint.add( kpar )
        ci = ivR

        new_ek = Btc::Hd::ExtendedKey.new
        new_ek.parent_key = self
        new_ek.keytype = PUBLIC_KEY
        new_ek.child_number = i
        new_ek.key = k  #key is stored as a point for public keys
        new_ek.depth = depth + 1
        new_ek.chain_code = ci
        new_ek
      end
    end

    def compress(public_key)
        public_key_string = public_key.to_bn.to_s(16)
        prefix = public_key_string.byteslice(-1).to_i(16) % 2 == 0 ? "02" : "03"
        public_key_string = prefix + public_key_string.byteslice(2..65)
        [ public_key_string ].pack('H*')
    end

    def serialize
      # 4 byte: version bytes (mainnet: 0x0488B21E public, 0x0488ADE4 private; testnet: 0x043587CF public, 0x04358394 private)
      # 1 byte: depth: 0x00 for master nodes, 0x01 for level-1 derived keys, ....
      # 4 bytes: the fingerprint of the parent's key (0x00000000 if master key)
      # 4 bytes: child number. This is ser32(i) for i in xi = xpar/i, with xi the key being serialized. (0x00000000 if master key)
      # 32 bytes: the chain code
      # 33 bytes: the public key or private key data (serP(K) for public keys, 0x00 || ser256(k) for private keys)

      if keytype == PRIVATE_KEY
        serialized_key = "\x00" + key
      elsif keytype == PUBLIC_KEY
        serialized_key = compress(key)
      end

      Btc::Base58.check(version,
        to_uint8_a(depth) +
        fingerprint +
        to_uint32_a(child_number).reverse +
        chain_code +
        serialized_key)
    end

    def deserialize(s)
      version, s = Btc::Base58.check_decode(s, true, 4)
      if version == MAINNET_PRIVATE_VERSION || version == TESTNET_PRIVATE_VERSION
        self.keytype = PRIVATE_KEY
      elsif version == MAINNET_PUBLIC_VERSION || version == TESTNET_PUBLIC_VERSION
        self.keytype = PUBLIC_KEY
      end
        
      self.depth = to_uint8(s.byteslice(0..0))
      self.parent_fingerprint = s.byteslice(1..4)
      self.child_number = to_uint32(s.byteslice(5..8).reverse)
      self.chain_code = s.byteslice(9..40)

      if self.keytype == PRIVATE_KEY
        self.key = s.byteslice(42..73)
      elsif self.keytype == PUBLIC_KEY
        self.key = s.byteslice(41..73)
      end
    end

    def fingerprint
      if depth == 0
        return ["00000000"].pack('H*')
      else
        hash160(compress(parent_key.public_key)).byteslice(0..3)
      end
    end

    def public_key
      if keytype == PRIVATE_KEY
        newk = OpenSSL::PKey::EC.new(GROUP_NAME)
        newk.generate_key
        newk.private_key = OpenSSL::BN.new( key.unpack('H*').first, 16 ) # kpar #kpar needs to be a bn
        newk.group.generator.mul(newk.private_key)
      elsif keytype == PUBLIC_KEY
        key
      end
    end


    def hash160(m)
      s2 = OpenSSL::Digest::SHA256.digest m
      OpenSSL::Digest::RIPEMD160.digest s2
    end

    def version
      retval = ""
      if @@network_type == NETWORK_TYPE_MAINNET
        if keytype == PUBLIC_KEY
          retval = MAINNET_PUBLIC_VERSION
        elsif keytype == PRIVATE_KEY
          retval = MAINNET_PRIVATE_VERSION
        end
      elsif @@network_type == NETWORK_TYPE_TESTNET
        if keytype == PUBLIC_KEY
          retval = TESTNET_PUBLIC_VERSION
        elsif keytype == PRIVATE_KEY
          retval = TESTNET_PRIVATE_VERSION
        end
      end
      retval
    end
  end
end