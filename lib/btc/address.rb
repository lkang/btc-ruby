# encoding: ASCII-8BIT
#address.rb

# use this class to: 
# create a new btc address, access the private / public keys for storage
# 
# create a new address. seed it with a private key, pubkey and address will
#  be recalculated. 
#
# create a new address. modify the pubkey (no private key)
#   get the address, hash160 - use these when creating a transaction. 
# 
module Btc
  class Address
    include OpenSSL

    attr_accessor :key, :privkey, :pubkey, :compressed, :set_pubkey_hash160, :multisig_pubkey

    GROUP_NAME = 'secp256k1'

    NETWORK_TYPE_MAINNET = 'mainnet'
    NETWORK_TYPE_TESTNET = 'testnet'

    ADDRESS_VERSION = "\x00"
    ADDRESS_MULTISIG_VERSION = "\x05"

    TESTNET_ADDRESS_VERSION = "\x6f"
    TESTNET_ADDRESS_MULTISIG_VERSION = "\xc4"



    class << self
      @@network_type = NETWORK_TYPE_MAINNET

      def network_type
        @@network_type
      end

      def network_type=(nt)
        @@network_type = nt
      end

      def valid?(b58check)
          begin
          r = Base58.decode b58check
        b58check == Base58.check( r.byteslice(0), r.byteslice(1,20) )
        rescue => e
          puts "Address::valid? failed: #{e.inspect}"
          false
        end
      end
    end

    def initialize
      self.compressed = true
      pk = PKey::EC.new(GROUP_NAME)
      self.key = pk.generate_key
      address
    end

    def address_version
      if Btc::Address.network_type == NETWORK_TYPE_MAINNET
        multisig_pubkey ? ADDRESS_MULTISIG_VERSION : ADDRESS_VERSION    
      else
        multisig_pubkey ? TESTNET_ADDRESS_MULTISIG_VERSION : TESTNET_ADDRESS_VERSION
      end
    end

    # returns binary pubkey
    def pubkey
      public_key_string = key.public_key.to_bn.to_s(16)
      if compressed
        prefix = public_key_string.byteslice(-1).to_i(16) % 2 == 0 ? "02" : "03"
        public_key_string = prefix + public_key_string.byteslice(2..65)
      end

      [ public_key_string ].pack('H*')
    end

    def pubkey=(d) #d is a binary 65 byte string. 04 <32 bytes x> <32 bytes y>
      self.compressed = d.byteslice(0) == "\x04" ? false : true # if compressed, address.key.pubkey is just a stored value
      group = OpenSSL::PKey::EC::Group.new(GROUP_NAME)
      coords = OpenSSL::BN.new( d.unpack('H*').first, 16 )
      point = OpenSSL::PKey::EC::Point.new(group, coords)
      key.public_key = point
      key.private_key = nil
    end

    # returns binary private key
    def privkey(add_compressed_suffix=false)
      compressed_suffix =  add_compressed_suffix && compressed ? "01" : ""
      [key.private_key.to_s(16) + compressed_suffix].pack('H*')
    end

    def privkey=(d) #d is a binary byte string
      self.compressed = (d.bytesize == 33) && (d.byteslice(-1).ord == 1)
      d = d.byteslice(0,32)

      key.private_key = OpenSSL::BN.new(d.unpack('H*').first, 16)
      key.public_key = key.group.generator.mul(key.private_key)
    end

    # returns base58 encoded address
    def address
      Base58.check( address_version, pubkey_hash160 )
    end

    # returns binary pubkey hash160
    def pubkey_hash160
      if set_pubkey_hash160
        set_pubkey_hash160 
      elsif multisig_pubkey
        hash160 multisig_pubkey
      else
        hash160( pubkey )
      end
    end

    def hash160(m)
      s2 = OpenSSL::Digest::SHA256.digest m
      OpenSSL::Digest::RIPEMD160.digest s2
    end

  end
end