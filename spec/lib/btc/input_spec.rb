# input_spec.rb
require 'spec_helper'

describe Btc do
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

  describe Btc::Input do
    let(:input) do 
      last_tx_raw = ["010000000164ff18f936ac1fba55e0c6943a58a33b18a59bccfbdb8913eb9322fc36f86960000000006b483045022100c8dc5980d80ad2c78ecb29af91d5e1c504f166c8de4b12635e622c4079a4dd7c0220270b2876ae887e82bcc23e01375720130ed8edaf41f28617112fae6b82c724de012103c30c0746e04f046134ffab3238ff49df542340330682df4a69763c692e06b379ffffffff02400d0300000000001976a914135abe8eeae756c23140e64a12037d5660f67e7588ac30629500000000001976a914802f9a4d94e18873716631daeee246c5e0d4467188ac00000000"].pack('H*')
      Btc::Input.new input_address, 'txid12345', last_tx_raw
    end

    context 'before signature' do
      describe '#scriptSig' do
        it 'returns the scriptPubKey of the previous tx indexed output' do 
          input.scriptSig.should == ["1976a914135abe8eeae756c23140e64a12037d5660f67e7588ac"].pack('H*')
        end
      end

      describe '#serialize' do
        it 'returns serialized data' do
          input.serialize.should == binhash_to_a(input.txid) + input.to_uint32_a( input.index ) + input.scriptSig + input.to_uint32_a( input.sequence_no )
          input.serialize.should == "#{binhash_to_a(input.txid)}#{["00000000"].pack('H*')}#{input.scriptSig}#{["ffffffff"].pack('H*')}"
        end
      end
    end

    context 'after signature' do
    end
  end
end




