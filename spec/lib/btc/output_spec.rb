# output_spec.rb
require 'spec_helper'

describe Btc::Output do
  include Btc::Types

  let(:output_address) do
    Btc::Address.new.tap do |a|
      a.pubkey = ["04c4b298c769761a188703a93dbb862a255593be2ebc590af46737b2f056a2638da7c613beb365bdf13f3f251e4c0a247ee7efa42bb8cce6b1d1a1363f407d4527"].pack('H*')
    end
  end

  let(:input_address) do
    Btc::Address.new.tap do |a|
      a.pubkey = ["0466a6308c6bfd5d1b988e649b358424bc61115b16d2d7431f2112b3b0af07062369e08ec9f065685d032b0fadd14df1423f1b303b2ed0b9757eada122206678aa"].pack('H*')
    end
  end

  let(:output) { Btc::Output.new output_address, 100 }

  describe '#scriptPubKey' do
    it 'creates a string of opcodes including pubkey hash' do 
      output.scriptPubKey.serialize.should == ["1976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188ac"].pack('H*')
      scriptPubKey_string = ["19"].pack('H*') + Btc::Script::OP_DUP + Btc::Script::OP_HASH160 + output_address.pubkey_hash160.bytesize.chr + output_address.pubkey_hash160 + Btc::Script::OP_EQUALVERIFY + Btc::Script::OP_CHECKSIG
      output.scriptPubKey.serialize.should == scriptPubKey_string
    end
  end

  describe '#serialize' do
    it 'returns serialized data' do
      output.serialize.should == ["64000000000000001976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188ac"].pack('H*')
      output.serialize.should == output.to_uint64_a(100) + output.scriptPubKey.serialize
    end
  end


  let(:output_string) { ["64000000000000001976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188ac"].pack('H*') }

  it 'creates an output parsedfrom a string' do
    # p = Btc::Output.new
    p = output
    p.parse output_string
    p.scriptPubKey.serialize.should == ["1976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188ac"].pack('H*')
    p.satoshis.should == 100
  end
end