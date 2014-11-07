# output.rb
module Btc

  class Output
    include Types

    attr_accessor :address, :satoshis, :scriptPubKey

    def initialize( address, satoshis )
      self.address = address
      self.satoshis = satoshis

      if address && address.multisig_pubkey
        self.scriptPubKey = Btc::Script::MultiSigPubKey.new(address.pubkey_hash160)
      else
        self.scriptPubKey = Btc::Script::PubKey.new(address.pubkey_hash160) if address
      end
    end

    # decode one output from raw bytestring, returns the remaining bytestring
    def parse(s)
      self.satoshis = to_uint64(s.byteslice(0..7))

      p = Btc::Script::Parser.new
      s = p.tokenize(s.byteslice(8..-1))

      self.address = Btc::Address.new

      #TODO - fix this. we dont always get a script with pubkey_hash160 (20). we could get a gen transaction, which puts the  longer (33) pubkey in here. 
      if p.pubkey_hash160.length <= 20
        self.address.set_pubkey_hash160 = p.pubkey_hash160
      else
        self.address.pubkey = p.pubkey_hash160
      end

      self.scriptPubKey = p
      s
    end

    def serialize
      to_uint64_a( satoshis ) + #number of satoshis (100_000_000 == 1BTC)
      scriptPubKey.serialize
    end
  end
end