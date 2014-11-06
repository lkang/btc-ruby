# encoding: ASCII-8BIT
# script_spec.rb
require 'spec_helper'

describe Btc::Script do
  let(:scriptPubKey_string) { "\x19v\xA9\x14\x1D\xBFo\x80\xC4\xC8/:\x1AK{\xB3\x9E[\xB1wh\xA7.\xF1\x88\xAC" }
  let(:pubkey_hash160) { "\x1D\xBFo\x80\xC4\xC8/:\x1AK{\xB3\x9E[\xB1wh\xA7.\xF1" }

  describe Btc::Script::Parser do
    let(:parser) { Btc::Script::Parser.new }

    describe '#tokenize' do
      it 'parses a scriptPubKey into tokens' do
        parser.tokenize( scriptPubKey_string )
        parser.tokens.count.should == 5
      end
    end

    describe '#single_byte_opcode' do
      it 'parses a single byte token' do
        t, raw = parser.single_byte_opcode( scriptPubKey_string.byteslice(1..-1) )
        t.op.should == Btc::Script::OP_DUP
        raw.should == scriptPubKey_string.byteslice(2..-1)
      end

      it 'single_byte_token returns nil for a multi byte token' do
        t, raw = parser.single_byte_opcode( scriptPubKey_string.byteslice(3..-1) )
        t.should be_nil
        raw.should == scriptPubKey_string.byteslice(3..-1) #be consistent
      end
    end

    describe '#multi_byte_opcode' do
      it 'parses a multi byte token' do
        t, raw = parser.multi_byte_opcode( scriptPubKey_string.byteslice(3..-1) )
        t.op.should == "\x14"
        t.data.should == scriptPubKey_string.byteslice(4,20)
        raw.should == scriptPubKey_string.byteslice(24..-1)
      end

      it 'does not parse an invalid multi byte token' do
        t, raw = parser.multi_byte_opcode( scriptPubKey_string.byteslice(1..-1) )
        t.should be_nil
        raw.should == scriptPubKey_string.byteslice(1..-1) 
      end
    end

    describe '#serialize' do
      it 'serializes the tokens with the bytecount prefix' do
        parser.tokenize(scriptPubKey_string)
        parser.serialize.should == scriptPubKey_string
      end
    end

    describe '#serialize_tokens' do
      it 'serializes the tokens without the bytecount prefix' do
        parser.tokenize(scriptPubKey_string)
        parser.serialize_tokens.should == scriptPubKey_string.byteslice(1..-1)
      end
    end

    describe '#pubkey_hash160' do
      it 'returns a guess at pubkey_hash160' do
        parser.tokenize(scriptPubKey_string)
        parser.pubkey_hash160.should == pubkey_hash160
      end
    end
  end

  describe Btc::Script::PubKey do
    describe '#serialize' do
      it 'creates a scriptPubKey bytestring' do
        k = Btc::Script::PubKey.new( pubkey_hash160 )
        k.serialize.should == scriptPubKey_string
      end
    end
  end

  describe Btc::Script::Sig do
    describe '#serialize' do
      it 'creates a scriptSig bytestring' do
        signature = "123456789"
        pubkey = "abcde"
        k = Btc::Script::Sig.new( signature, pubkey )
        k.serialize.should == "\x10\x09123456789\x05abcde"
      end
    end
  end

  describe Btc::Script::RedeemScript do
    before do
      Btc::Address.network_type = Btc::Address::NETWORK_TYPE_MAINNET
    end
    
    describe '#redeem_script' do
      it 'serializes 2 addresses and creates tokens into a valid redeemScript' do
        s = Btc::Script::RedeemScript.new( 2, [["03d06e98ecb432ba143ace42b3eaebdb543066060f074c01bc37a6fa5fb7275011"].pack('H*'), ["03e585cfe1a6db8262f5152e994380a6b364b4767170403d48554880fd102896c3"].pack('H*')])
        s.redeem_script.should == ["522103d06e98ecb432ba143ace42b3eaebdb543066060f074c01bc37a6fa5fb72750112103e585cfe1a6db8262f5152e994380a6b364b4767170403d48554880fd102896c352ae"].pack('H*')
      end

      # from https://gist.github.com/gavinandresen/3966071
      it 'serializes a 2/3 multisig into a redeem script' do
        s = Btc::Script::RedeemScript.new( 2, [
          ["0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86"].pack('H*'),
          ["04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874"].pack('H*'),
          ["048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213"].pack('H*')
          ])
        s.redeem_script.should == ["52410491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f864104865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec687441048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d4621353ae"].pack('H*')

        # hash_160 the redeem_script = P2SH address
        s2 = OpenSSL::Digest::SHA256.digest s.redeem_script
        h160 = OpenSSL::Digest::RIPEMD160.digest s2

        puts "***** h160: #{h160.unpack('H*')}"
        a = Btc::Base58.check(["05"].pack('H*'), h160)
        a.should == "3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC"

        addr1 = Btc::Address.new
        addr1.multisig_pubkey = s.redeem_script

        h160 = addr1.pubkey_hash160
        puts "***** h160: #{h160.unpack('H*')}"
        a = addr1.address
        a.should == "3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC"
      end
    end
  end



end