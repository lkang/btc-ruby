# input.rb
module Btc

  class Input
    include Types

    attr_accessor :address, :txid, :previous_tx, :index,
      :sig, :presig_mode, :sequence_no, :scriptPubKey, :parsedScriptSig,
      :zeroed,
      :redeemScript, :p2shScriptSig, :addresses

    def initialize( address, txid, previous_tx) #index, scriptPubKey )
      self.address = address
      self.txid = txid #should this be the entire transaction or just the hash (id)?
      self.previous_tx = previous_tx #binary of the previous transaction.
      # self.scriptPubKey = scriptPubKey
      self.presig_mode = true
      self.sequence_no = to_uint32( ["ffffffff"].pack('H*') )
      self.index = 0 #or calculated from previous_tx and address
      pre_sig
    end

    # for P2SH, scriptPubKey will be the redeemScript
    def set_previous( txid, index, scriptPubKey )
      self.txid = txid
      self.index = index
      s = Btc::Script::Parser.new
      s.tokenize( to_varint(scriptPubKey.size) + scriptPubKey )
      self.scriptPubKey = s
    end

    def set_multisig( addresses, txid, index, redeemScript ) #init with p2sh 
      self.addresses = addresses
      self.txid = txid
      self.index = index
      self.redeemScript = redeemScript
      self.p2shScriptSig = Btc::Script::P2SHScriptSig.new( redeemScript )
    end

    def serialize
      binhash_to_a( txid ) + #32 bytes - previous_txid
      to_uint32_a( index ) + # to_uint32_a - index of output in previous_tx
      scriptSig +
      to_uint32_a( sequence_no )
    end

    def scriptSig
      # op_sig + op_pubkey
      return ["00"].pack('H*') if zeroed

      if presig_mode
        redeemScript && redeemScript.redeem_script ||
        scriptPubKey && scriptPubKey.serialize ||
        pre_sig.serialize
      else
        parsedScriptSig && parsedScriptSig.serialize || 
        p2shScriptSig && p2shScriptSig.serialize ||
        Btc::Script::Sig.new(sig, address.pubkey).serialize
      end
    end

    def pre_sig
      # return bogus data if no previous tx 
      return Btc::Script::PubKey.new(address.pubkey_hash160) if previous_tx.nil? || previous_tx.empty?

      last_tx = Tx.new [], []
      last_tx.parse(previous_tx)
      last_tx.outputs.each_with_index do |output,i|
        self.index = i if output.address.address == address.address
      end
      last_tx.outputs[index].scriptPubKey
    end

    # def op_pubkey
    #   k = @address.pubkey
    #   k.bytes.count.chr + k
    # end

    def parse(s)
      self.presig_mode = false

      self.txid, s = to_binhash(s,32)

      self.index = to_uint32(s.byteslice(0,4))

      if s.byteslice(0,4) == ["ffffffff"].pack('H*') && self.txid == ["0000000000000000000000000000000000000000000000000000000000000000"].pack('H*')
        generation = true
      end

      p = Btc::Script::Parser.new

      s = p.tokenize(s.byteslice(4..-1))
      
      self.address.pubkey = p.tokens.last.data if !generation
      
      self.parsedScriptSig = p

      self.sequence_no = to_uint32(s.byteslice(0..3))
      s.byteslice(4..-1)
    end

    def sign(txhash)
      self.presig_mode = false
      if redeemScript
        addresses.each do |address|
          s = address.key.dsa_sign_asn1(txhash) + ["01"].pack('H*')
          self.p2shScriptSig.add_signature(s) 
        end
      else
        s = address.key.dsa_sign_asn1(txhash) + ["01"].pack('H*')
        self.sig = s  
      end
    end

    def verify_sig(txhash)
      address.key.dsa_verify_asn1(txhash, sig)
    end

    def debug_dump
      puts "******* Input:"
      fields = [:txid, :previous_tx, :index, :sig, :presig_mode, :sequence_no]
      puts "address:     #{address.address}"
      puts "txid:        #{txid.unpack('H*')}"
      puts "previous_tx: #{previous_tx.to_s.unpack('H*')}"
      puts "index:       #{to_uint32_a(index).unpack('H*')}"
      puts "sig:         #{sig.unpack('H*')}"
      puts "presig_mode: #{presig_mode.inspect}"
      puts "sequence_no: #{to_uint32_a(sequence_no).unpack('H*')}"
    end

  end
end