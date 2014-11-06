# encoding: ASCII-8BIT
# bitcoin_utils_spec.rb
require 'spec_helper'

describe Btc::Base58 do
  describe '.encode' do
    #big endian data
    it 'encodes a binary number into Base58' do
      Btc::Base58.encode("\x01").should == '2'
      Btc::Base58.encode("\x10").should == 'H'
      Btc::Base58.encode("\x41").should == '28'
      Btc::Base58.encode("\x02\x44").should == 'B1' #'62M'
      Btc::Base58.encode("\x00\x02\x44").should == '1B1' #'62M'
      Btc::Base58.encode("\x00\x00\x02\x44").should == '11B1' #'62M'
      Btc::Base58.encode("o!R\r\xEE~6\v{3\x06\xA1\xF6&\xA9\xD1\x00\xB6\xE7\xEF\xC8\xDD\xA1\x8A:").should == "miZ8tdESTy1z1DcVMFECopnf96oEZFR2Q1"
    end

    it 'runs bitcoind tests properly' do
      testcases = [
        ["", ""],
        ["61", "2g"],
        ["626262", "a3gV"],
        ["636363", "aPEr"],
        ["73696d706c792061206c6f6e6720737472696e67", "2cFupjhnEsSn59qHXstmK2ffpLv2"],
        ["00eb15231dfceb60925886b67d065299925915aeb172c06647", "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"],
        ["516b6fcd0f", "ABnLTmg"],
        ["bf4f89001e670274dd", "3SEo3LWLoPntC"],
        ["572e4794", "3EFU7m"],
        ["ecac89cad93923c02321", "EJDM8drfXA6uyA"],
        ["10c8511e", "Rt5zm"],
        ["00000000000000000000", "1111111111"]
      ]
      testcases.each do |testcase|
        r = Btc::Base58.encode( [testcase.first].pack('H*') )
        r.should == testcase.last
      end
    end


  end

  describe '.decode' do
    #big endian
    it 'decodes a base58 string into a byte array' do
      Btc::Base58.decode('2').should == "\x01"
      Btc::Base58.decode('H').should == "\x10"
      Btc::Base58.decode('28').should == "\x41"
      Btc::Base58.decode('B1').should == "\x02\x44"
      Btc::Base58.decode('1B1').should == "\x00\x02\x44"
      Btc::Base58.decode('11B1').should == "\x00\x00\x02\x44"
      Btc::Base58.decode("miZ8tdESTy1z1DcVMFECopnf96oEZFR2Q1").should == "o!R\r\xEE~6\v{3\x06\xA1\xF6&\xA9\xD1\x00\xB6\xE7\xEF\xC8\xDD\xA1\x8A:"
    end


    it 'runs bitcoind tests properly' do
      testcases = [
        ["", ""],
        ["61", "2g"],
        ["626262", "a3gV"],
        ["636363", "aPEr"],
        ["73696d706c792061206c6f6e6720737472696e67", "2cFupjhnEsSn59qHXstmK2ffpLv2"],
        ["00eb15231dfceb60925886b67d065299925915aeb172c06647", "1NS17iag9jJgTHD1VXjvLCEnZuQ3rJDE9L"],
        ["516b6fcd0f", "ABnLTmg"],
        ["bf4f89001e670274dd", "3SEo3LWLoPntC"],
        ["572e4794", "3EFU7m"],
        ["ecac89cad93923c02321", "EJDM8drfXA6uyA"],
        ["10c8511e", "Rt5zm"],
        ["00000000000000000000", "1111111111"]
      ]
      testcases.each do |testcase|
        r = Btc::Base58.decode( testcase.last )
        r.should == [testcase.first].pack('H*')
      end
    end

  end

  # encoding a bytestring to Btc::Base58check string
  #  test data from http://sourceforge.net/mailarchive/forum.php?thread_name=CAPg%2BsBhDFCjAn1tRRQhaudtqwsh4vcVbxzm%2BAA2OuFxN71fwUA%40mail.gmail.com&forum_name=bitcoin-development
  describe '.check' do
    it 'creates a base58check' do
      #32 byte private key (uncompressed public)
      r = Btc::Base58.check( "\x80", ["1111111111111111111111111111111111111111111111111111111111111111"].pack('H*') )
      r.should == '5HwoXVkHoRM8sL2KmNRS217n1g8mPPBomrY7yehCuXC1115WWsh'
      r = Btc::Base58.check( "\x80", ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"].pack('H*') )
      r.should == '5KVzsHJiUxgvBBgtVS7qBTbbYZpwWM4WQNCCyNSiuFCJzYMxg8H'
      r = Btc::Base58.check( "\x80", ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b012"].pack('H*') )
      r.should == '5JMys7YfK72cRVTrbwkq5paxU7vgkMypB55KyXEtN5uSnjV7K8Y'

      #33 byte private key (compressed public)
      r = Btc::Base58.check( "\x80", ["111111111111111111111111111111111111111111111111111111111111111101"].pack('H*') )
      r.should == 'KwntMbt59tTsj8xqpqYqRRWufyjGunvhSyeMo3NTYpFYzZbXJ5Hp'
      r = Btc::Base58.check( "\x80", ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd01"].pack('H*') )
      r.should == 'L4ezQvyC6QoBhxB4GVs9fAPhUKtbaXYUn8YTqoeXwbevQq4U92vN'
      r = Btc::Base58.check( "\x80", ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b01201"].pack('H*') )
      r.should == 'KydbzBtk6uc7M6dXwEgTEH2sphZxSPbmDSz6kUUHi4eUpSQuhEbq'
    end

  end

  # decoding a base58check to a bytestring payload
  describe '.check_decode' do
    it 'decodes a base58check into a prefix and payload' do
      r = Btc::Base58.check_decode('5HwoXVkHoRM8sL2KmNRS217n1g8mPPBomrY7yehCuXC1115WWsh')
      r.first.should == "\x80"
      r.last.should == ["1111111111111111111111111111111111111111111111111111111111111111"].pack('H*')
      r = Btc::Base58.check_decode('5KVzsHJiUxgvBBgtVS7qBTbbYZpwWM4WQNCCyNSiuFCJzYMxg8H')
      r.first.should == "\x80"
      r.last.should == ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"].pack('H*')
      r = Btc::Base58.check_decode('5JMys7YfK72cRVTrbwkq5paxU7vgkMypB55KyXEtN5uSnjV7K8Y')
      r.first.should == "\x80"
      r.last.should == ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b012"].pack('H*')

      r = Btc::Base58.check_decode('KwntMbt59tTsj8xqpqYqRRWufyjGunvhSyeMo3NTYpFYzZbXJ5Hp')
      r.first.should == "\x80"
      r.last.should == ["111111111111111111111111111111111111111111111111111111111111111101"].pack('H*')
      r = Btc::Base58.check_decode('L4ezQvyC6QoBhxB4GVs9fAPhUKtbaXYUn8YTqoeXwbevQq4U92vN')
      r.first.should == "\x80"
      r.last.should == ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd01"].pack('H*')
      r = Btc::Base58.check_decode('KydbzBtk6uc7M6dXwEgTEH2sphZxSPbmDSz6kUUHi4eUpSQuhEbq')
      r.first.should == "\x80"
      r.last.should == ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b01201"].pack('H*')
    end

    it 'raises an error if the base58check is not valid' do
      expect{ Btc::Base58.check_decode('112341234134') }.to raise_error('invalid Btc::Base58check')
      expect{ Btc::Base58.check_decode('xKydbzBtk6uc7M6dXwEgTEH2sphZxSPbmDSz6kUUHi4eUpSQuhEbq') }.to raise_error('invalid Btc::Base58check')
    end

    it 'does not raise an error on invalid Btc::Base58check if validate=false' do
      expect{ Btc::Base58.check_decode('112341234134', false) }.not_to raise_error
      expect{ Btc::Base58.check_decode('xKydbzBtk6uc7M6dXwEgTEH2sphZxSPbmDSz6kUUHi4eUpSQuhEbq',false) }.not_to raise_error
    end
  end
end