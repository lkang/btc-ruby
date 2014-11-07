# encoding: ASCII-8BIT
# script.rb
module Btc
  module Script

# typical transaction: 
# scriptPubKey: OP_DUP OP_HASH160 <pubKeyHash> OP_EQUALVERIFY OP_CHECKSIG
# scriptSig: <sig> <pubKey>

    #constants
    OP_0 = "\x00" # 
    OP_FALSE = "\x00" # OP_0
    #OP_PUSHDATA - 0x01 - 0x4b - this many bytes will be pushed 
    OP_PUSHDATA1 = "\x4c"  #next byte contains how many bytes will follow
    OP_PUSHDATA2 = "\x4d"  #next 2 bytes
    OP_PUSHDATA4 = "\x4e"  #next 4 bytes
    OP_1NEGATE = "\x4f"
    OP_TRUE = "\x51" # OP_1
    OP_1 = "\x51"
    #OP_2 - OP_16  # 0x52-0x60 the number in the word name will be pushed

    #stack
    OP_DUP = "\x76"

    #bitwise logic
    OP_EQUAL = "\x87"
    OP_EQUALVERIFY = "\x88"

    # crypto
    OP_RIPEMD160 = "\xa6"
    OP_SHA1 = "\xa7"
    OP_SHA256 = "\xa8"
    OP_HASH160 = "\xa9"
    OP_HASH256 = "\xaa"
    OP_CODESEPARATOR = "\xab"
    OP_CHECKSIG = "\xac"
    OP_CHECKSIGVERIFY = "\xad"
    OP_CHECKMULTISIG = "\xae"
    OP_CHECKMULTISIGVERIFY = "\xaf"

    # pseudo
    OP_PUBKEYHASH = "\xfd"
    OP_PUBKEY = "\xfe"
    OP_INVALIDOPCODE = "\xff"

    module SerializeTokens
      include Types

      #with varint bytecount
      def serialize
        s = serialize_tokens
        to_varint( s.bytesize ) + s
      end

      #without the bytecout
      def serialize_tokens
        tokens.map(&:serialize).join
      end
    end

    class Parser
      include Types
      include SerializeTokens

      attr_accessor :tokens

      def single_byte_opcode( raw )
        c = raw.byteslice(0)
        t = Token.new( c ) if [
          OP_FALSE,
          OP_1NEGATE,
          OP_TRUE,
          OP_DUP,
          OP_EQUAL,
          OP_EQUALVERIFY,
          OP_RIPEMD160,
          OP_SHA1,
          OP_SHA256,
          OP_HASH160,
          OP_HASH256,
          OP_CODESEPARATOR,
          OP_CHECKSIG,
          OP_CHECKSIGVERIFY,
          OP_CHECKMULTISIG,
          OP_CHECKMULTISIGVERIFY,
          OP_PUBKEYHASH,
          OP_PUBKEY,
          OP_INVALIDOPCODE
        ].include? c
        raw = raw.byteslice(1..-1) if t

        [t, raw]
      end

      def multi_byte_opcode( raw )
        op = raw.byteslice(0)
        if op.ord >= 1 && op.ord <= 0x4b
          len = op.ord
          data_index = 1
        elsif op == OP_PUSHDATA1
          len = to_uint8( raw.byteslice(1) )
          data_index = 2
        elsif op == OP_PUSHDATA2
          len = to_uint16( raw.byteslice(1..2) )
          data_index = 3
        elsif op == OP_PUSHDATA4
          len = to_uint32( raw.byteslice(1..4) )
          data_index = 5
        else
          len = 0
          data_index = 0
        end

        if len > 0
          t = Token.new(op, raw.byteslice(data_index,len))
          raw = raw.byteslice(data_index+len..-1)
        else
          t = nil
        end
        [t, raw]
      end

      def get_token(raw)
        t, raw = single_byte_opcode( raw )
        t, raw = multi_byte_opcode( raw ) if t.nil?
        [t, raw]
      end

      def tokenize(raw)
        size, raw = to_vint(raw)
        rem = raw.byteslice(size..-1)
        raw = raw.byteslice(0,size)

        self.tokens = []
        while raw.length > 0
          t, raw = get_token(raw)
          self.tokens.push(t) unless t.nil?
        end
        rem
      end

      # assume the first token with data is the pubkey_hash160 
      #   This only works with a 'standard transaction' scriptPubKey
      def pubkey_hash160
        pkt = tokens.select{|t| !t.data.nil? }
        pkt.first.data
      end
    end

    class Token < Struct.new( :op, :data )
      def serialize
        op + data.to_s
      end
    end

    # implements standard transaction scriptPubKey from an pubkey hash:
    #  OP_DUP + OP_HASH160 + pubkey_hash160 + OP_EQUALVERIFY + OP_CHECKSIG
    class PubKey < Struct.new( :pubkey_hash160 )
      include SerializeTokens
      def tokens
        [
          Token.new( OP_DUP ),
          Token.new( OP_HASH160 ),
          Token.new( pubkey_hash160.bytesize.chr, pubkey_hash160 ),
          Token.new( OP_EQUALVERIFY ),
          Token.new( OP_CHECKSIG )
        ]
      end
    end

    # implements standard transaction scriptSig from signature and pubkey
    #  signature + pubkey
    class Sig < Struct.new( :signature, :pubkey )
      include SerializeTokens
      def tokens
        [
          Token.new( signature.bytesize.chr, signature ),
          Token.new( pubkey.bytesize.chr, pubkey ),
        ]
      end
    end

    class RedeemScript < Struct.new( :required, :pubkeys ) #rename to RedeemScript
      include SerializeTokens

      def tokens
        [Token.new( (OP_1.ord + required - 1).chr )] +
        pubkeys.map {|key| Token.new( key.bytesize.chr, key ) } +
        [
          Token.new( (OP_1.ord + pubkeys.size - 1).chr ),
          Token.new( OP_CHECKMULTISIG )
        ]
      end

      def hash160(m)
        s2 = OpenSSL::Digest::SHA256.digest redeem_script
        OpenSSL::Digest::RIPEMD160.digest s2
      end

      def address
        output_address = Btc::Address.new
        output_address.multisig_pubkey = redeem_script
        output_address.address
      end

      def redeem_script
        to_vint(serialize).last
      end
    end

    class MultiSigPubKey < Struct.new( :h160 )
      include SerializeTokens

      def tokens
        [
          Token.new( OP_HASH160 ), #a9 = OP_HASH160
          Token.new( h160.bytesize.chr, h160 ),
          Token.new( OP_EQUAL ) #87 = OP_EQUAL
        ]
      end
    end

    class P2SHScriptSig < Struct.new( :redeemScript )
      include SerializeTokens

      def signature_tokens
        @signature_tokens ||= [ Token.new( OP_0 ) ]
      end

      def tokens
        rs_size = redeemScript.redeem_script.size
        signature_tokens + [Token.new(op_push(rs_size), redeemScript.redeem_script)]
      end

      def add_signature( signature )
        @signature_tokens = signature_tokens + [Token.new(signature.bytesize.chr, signature)]
      end

      def op_push(n)
        if n <= 75
          op = n.chr
        elsif n < 256
          op = OP_PUSHDATA1 + n.chr
        elsif n < 256*256
          op = OP_PUSHDATA2 + to_uint16_a(n)
        elsif n < 256*256*256*256
          op = OP_PUSHDATA4 + to_uint32_a(n)
        end
        op
      end
    end

  end
end
