# transaction_spec.rb
require 'spec_helper'

require 'btc/tx'
require 'btc/types'

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

  describe Btc::Tx do
    let(:input_address) do
      Btc::Address.new.tap do |a|
        a.privkey = ["01"].pack('H*')
      end
    end

    let(:output_address1) do
      Btc::Address.new.tap do |a|
        a.privkey = ["02"].pack('H*')
      end
    end

    let(:output_address2) do
      Btc::Address.new.tap do |a|
        a.privkey = ["03"].pack('H*')
      end
    end

    let(:input) do
      last_tx_raw = ["010000000164ff18f936ac1fba55e0c6943a58a33b18a59bccfbdb8913eb9322fc36f86960000000006b483045022100c8dc5980d80ad2c78ecb29af91d5e1c504f166c8de4b12635e622c4079a4dd7c0220270b2876ae887e82bcc23e01375720130ed8edaf41f28617112fae6b82c724de012103c30c0746e04f046134ffab3238ff49df542340330682df4a69763c692e06b379ffffffff02400d0300000000001976a914135abe8eeae756c23140e64a12037d5660f67e7588ac30629500000000001976a914802f9a4d94e18873716631daeee246c5e0d4467188ac00000000"].pack('H*')
      Btc::Input.new input_address, 'txid12345', last_tx_raw
    end

    let(:output1) do
      Btc::Output.new output_address, 100
    end

    let(:output2) do
      Btc::Output.new output_address, 200
    end

    it 'initializes with presig data' do
      tx = Btc::Tx.new( [input], [output1, output2] )
      tx.outputs.count.should == 2
      tx.inputs.count.should == 1

      # version +
      # in_counter +
      # list_of_inputs +
      # out_counter + 
      # list_of_outputs +
      # lock_time +
      # hashtype
      tx.serialize.should == ["0100000001353433323164697874000000001976a914135abe8eeae756c23140e64a12037d5660f67e7588acffffffff0264000000000000001976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188acc8000000000000001976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188ac0000000001000000"].pack('H*')
      tx.txhash.should == ["45cabb925036991747c6df82972172c0a8de345fdf9e05f9485cded8e13c547b"].pack('H*')
      tx.inputs.each do |input|
        expect(input.presig_mode).to eq true
      end
    end

    it 'initializes with presig data' do
      tx = Btc::Tx.new( [input], [output1, output2] )
      pre_sign_serialize = tx.serialize
      pre_sign_txhash = tx.txhash
      tx.sign
      tx.inputs.each do |input|
        puts "****** input.presig_mode: #{input.presig_mode.inspect}"
        expect(input.presig_mode).to eq false
      end
      tx.serialize.should_not == pre_sign_serialize

      tx.inputs.first.verify_sig(pre_sign_txhash).should == true

    end

    context 'parsing' do
      before do
        Btc::Address.network_type = Btc::Address::NETWORK_TYPE_TESTNET
      end

      describe '#parse' do
        it 'parses a generation transaction' do
          raw_tx = ["01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0d0381b4020131062f503253482fffffffff012040062a01000000232102fc85bda47334d2a8e2dc8e87d49486c0f726b5c9aa4880d7ecd1614fa7076abbac00000000"].pack('H*')
          p = Btc::Tx.new [], [], false
          p.parse(raw_tx)

          p.outputs.first.address.address.should == 'moJ4zEfNS62THN3hGt417crmpbDLizXEq5'
          p.outputs.first.scriptPubKey.serialize.should == ["232102fc85bda47334d2a8e2dc8e87d49486c0f726b5c9aa4880d7ecd1614fa7076abbac"].pack('H*')
          p.serialize.should == raw_tx
        end

        it 'parses a normal transaction' do
          raw_tx = ["01000000015c0040dbc6103d4d2c14d31650831b6777e335b42e04d83e4aa7df42c34e8797000000006b483045022018a78085b76214c1dddb5adc3c251d1a46440d909e637b713fc70a646763030e022100f166dfc6d8b5a7dbe982d0c601c894b1ffef9ece7d4e4acadbb6ab62ed61015c0121027676e7bd4bba4aa951b3e39f8f125b1d383f09c03e57212ea252a46d70195c6bffffffff02c9fcb706000000001976a91427d74a07600e11c23d122035ac2b95011526729b88ac9c5fbcd9150000001976a91421e765bd9b6d21d93df59620e0b34a795e79093488ac00000000"].pack('H*')
          p = Btc::Tx.new [], [], false
          p.parse(raw_tx)
          p.outputs.first.address.address.should == 'mj9cZ69S3RpyaN76d2eDoG8uUcXDFErKzr'
          p.outputs.first.scriptPubKey.serialize.should == ["1976a91427d74a07600e11c23d122035ac2b95011526729b88ac"].pack('H*')
          p.serialize.should == raw_tx
        end
      end
    end

  end

  #
  # Test #2 - take an existing transaction and check the signatures
  #
  # 2.0.0p353 :016 > api.request api.getrawtransaction('979724fd853111dd6f031e4bfece343e9e4594439fb4ceed0d30f46e1bc3924e', 1)
  # ****** get request to: "http://localhost:18332"
  #  => {"result"=>{"hex"=>"010000000177f5a623a208b2b446e98765e070e5bb3bdf7ca2622e028ac5d19e40a0a30ff0000000006b483045022100f1838b9f6e886dc387c43e1b06645e7b9dadd685261e6a2441468efd64185658022078a6ad04463e4cb6747e532d653ece5bcd161eec70bdff9bb24b6684b88e223e012102c7a7d96c7f2b0be316b4c13b9a31b77e0c7bae31cb79143b62c762b561eb2dd6ffffffff02705d1e00000000001976a914af77cd716e2044f96d6dedcc20e6385e9a007fd288acc0c62d00000000001976a91454dd4315a9c564d7e9ddb7acc2b6d5ac9f858d3388ac00000000", "txid"=>"979724fd853111dd6f031e4bfece343e9e4594439fb4ceed0d30f46e1bc3924e", "version"=>1, "locktime"=>0, "vin"=>[{"txid"=>"f00fa3a0409ed1c58a022e62a27cdf3bbbe570e06587e946b4b208a223a6f577", "vout"=>0, "scriptSig"=>{"asm"=>"3045022100f1838b9f6e886dc387c43e1b06645e7b9dadd685261e6a2441468efd64185658022078a6ad04463e4cb6747e532d653ece5bcd161eec70bdff9bb24b6684b88e223e01 02c7a7d96c7f2b0be316b4c13b9a31b77e0c7bae31cb79143b62c762b561eb2dd6", "hex"=>"483045022100f1838b9f6e886dc387c43e1b06645e7b9dadd685261e6a2441468efd64185658022078a6ad04463e4cb6747e532d653ece5bcd161eec70bdff9bb24b6684b88e223e012102c7a7d96c7f2b0be316b4c13b9a31b77e0c7bae31cb79143b62c762b561eb2dd6"}, "sequence"=>4294967295}], "vout"=>[{"value"=>0.0199, "n"=>0, "scriptPubKey"=>{"asm"=>"OP_DUP OP_HASH160 af77cd716e2044f96d6dedcc20e6385e9a007fd2 OP_EQUALVERIFY OP_CHECKSIG", "hex"=>"76a914af77cd716e2044f96d6dedcc20e6385e9a007fd288ac", "reqSigs"=>1, "type"=>"pubkeyhash", "addresses"=>["mwWk4earhNSVj1TYfCxVxnwQUp51KFSKmc"]}}, {"value"=>0.03, "n"=>1, "scriptPubKey"=>{"asm"=>"OP_DUP OP_HASH160 54dd4315a9c564d7e9ddb7acc2b6d5ac9f858d33 OP_EQUALVERIFY OP_CHECKSIG", "hex"=>"76a91454dd4315a9c564d7e9ddb7acc2b6d5ac9f858d3388ac", "reqSigs"=>1, "type"=>"pubkeyhash", "addresses"=>["moFg7iyQ6nxMXcD2wvawKGmPvAbEpaaW5u"]}}], "blockhash"=>"00000000000ba94496ad8e4e63d61ac69c3cf6de4363d89c927e980cd09ee708", "confirmations"=>14425, "time"=>1390010423, "blocktime"=>1390010423}, "error"=>nil, "id"=>7} 
  # 2.0.0p353 :017 > api.request api.getrawtransaction('f00fa3a0409ed1c58a022e62a27cdf3bbbe570e06587e946b4b208a223a6f577', 1)
  # ****** get request to: "http://localhost:18332"
  #  => {"result"=>{"hex"=>"01000000013e2b743ccf9c91a1ec9779083bbd9b1669393d3d8d5c1d91b523eafbf849c4aa010000006a4730440220566e6f44fa56e2f86340a34995aee2817cd91711bedefb892bc1a8fd5f3441e30220145634f6a9d1b6dcf5f0c456019fc0f91bc28ca3d22df9c74ea3ff1ddbc6d04701210222ae43735724fe1abd005fc1f1a7a36c06163e590c7a455406436b067c35cca4ffffffff02404b4c00000000001976a91427d74a07600e11c23d122035ac2b95011526729b88aca0c67f05000000001976a9140149e2e3245d41790e6d4f0f1c8cd1697bc29f0e88ac00000000", "txid"=>"f00fa3a0409ed1c58a022e62a27cdf3bbbe570e06587e946b4b208a223a6f577", "version"=>1, "locktime"=>0, "vin"=>[{"txid"=>"aac449f8fbea23b5911d5c8d3d3d3969169bbd3b087997eca1919ccf3c742b3e", "vout"=>1, "scriptSig"=>{"asm"=>"30440220566e6f44fa56e2f86340a34995aee2817cd91711bedefb892bc1a8fd5f3441e30220145634f6a9d1b6dcf5f0c456019fc0f91bc28ca3d22df9c74ea3ff1ddbc6d04701 0222ae43735724fe1abd005fc1f1a7a36c06163e590c7a455406436b067c35cca4", "hex"=>"4730440220566e6f44fa56e2f86340a34995aee2817cd91711bedefb892bc1a8fd5f3441e30220145634f6a9d1b6dcf5f0c456019fc0f91bc28ca3d22df9c74ea3ff1ddbc6d04701210222ae43735724fe1abd005fc1f1a7a36c06163e590c7a455406436b067c35cca4"}, "sequence"=>4294967295}], "vout"=>[{"value"=>0.05, "n"=>0, "scriptPubKey"=>{"asm"=>"OP_DUP OP_HASH160 27d74a07600e11c23d122035ac2b95011526729b OP_EQUALVERIFY OP_CHECKSIG", "hex"=>"76a91427d74a07600e11c23d122035ac2b95011526729b88ac", "reqSigs"=>1, "type"=>"pubkeyhash", "addresses"=>["mj9cZ69S3RpyaN76d2eDoG8uUcXDFErKzr"]}}, {"value"=>0.9226, "n"=>1, "scriptPubKey"=>{"asm"=>"OP_DUP OP_HASH160 0149e2e3245d41790e6d4f0f1c8cd1697bc29f0e OP_EQUALVERIFY OP_CHECKSIG", "hex"=>"76a9140149e2e3245d41790e6d4f0f1c8cd1697bc29f0e88ac", "reqSigs"=>1, "type"=>"pubkeyhash", "addresses"=>["mfdmUxK7HbkdDPW9kZdxyD6HX7mJTUUNDe"]}}], "blockhash"=>"00000000f918fa960fee732e0f4b8b7be14846c261cb600b96695e083ae1f1d3", "confirmations"=>14597, "time"=>1389891458, "blocktime"=>1389891458}, "error"=>nil, "id"=>8} 
  context 'with a known transaction and previous transaction' do
    describe '#sign' do
      it 'signs a transaction correctly' do


        # Get the address/keys that match the input for the transaction
        #
        # Parse the transaction
        #
        # Get the input 
        #
        # lookup the previous tx and get the output scriptPubKey
        #
        # place the scriptPubKey into the current transaction 
        #
        # hash the current transaction - check if this hash matches anything... 
        # 
        # sign the hash with the address privkey - check if it matches the tx's input scriptSig second field

        tx_s = ["010000000177f5a623a208b2b446e98765e070e5bb3bdf7ca2622e028ac5d19e40a0a30ff0000000006b483045022100f1838b9f6e886dc387c43e1b06645e7b9dadd685261e6a2441468efd64185658022078a6ad04463e4cb6747e532d653ece5bcd161eec70bdff9bb24b6684b88e223e012102c7a7d96c7f2b0be316b4c13b9a31b77e0c7bae31cb79143b62c762b561eb2dd6ffffffff02705d1e00000000001976a914af77cd716e2044f96d6dedcc20e6385e9a007fd288acc0c62d00000000001976a91454dd4315a9c564d7e9ddb7acc2b6d5ac9f858d3388ac00000000"].pack('H*')
        tx_s_id = ["979724fd853111dd6f031e4bfece343e9e4594439fb4ceed0d30f46e1bc3924e"].pack('H*')
        prev_tx_s = ["01000000013e2b743ccf9c91a1ec9779083bbd9b1669393d3d8d5c1d91b523eafbf849c4aa010000006a4730440220566e6f44fa56e2f86340a34995aee2817cd91711bedefb892bc1a8fd5f3441e30220145634f6a9d1b6dcf5f0c456019fc0f91bc28ca3d22df9c74ea3ff1ddbc6d04701210222ae43735724fe1abd005fc1f1a7a36c06163e590c7a455406436b067c35cca4ffffffff02404b4c00000000001976a91427d74a07600e11c23d122035ac2b95011526729b88aca0c67f05000000001976a9140149e2e3245d41790e6d4f0f1c8cd1697bc29f0e88ac00000000"].pack('H*')
        prev_tx_s_id = ["f00fa3a0409ed1c58a022e62a27cdf3bbbe570e06587e946b4b208a223a6f577"].pack('H*')

        prev_tx_output_scriptPubKey = ["76a91427d74a07600e11c23d122035ac2b95011526729b88ac"].pack('H*')

        known_inputaddr = 'mj9cZ69S3RpyaN76d2eDoG8uUcXDFErKzr'
        known_pubkey = ["02c7a7d96c7f2b0be316b4c13b9a31b77e0c7bae31cb79143b62c762b561eb2dd6"].pack('H*')
        known_scriptSig = ["483045022100f1838b9f6e886dc387c43e1b06645e7b9dadd685261e6a2441468efd64185658022078a6ad04463e4cb6747e532d653ece5bcd161eec70bdff9bb24b6684b88e223e012102c7a7d96c7f2b0be316b4c13b9a31b77e0c7bae31cb79143b62c762b561eb2dd6"].pack('H*')
        known_sig =         ["3045022100f1838b9f6e886dc387c43e1b06645e7b9dadd685261e6a2441468efd64185658022078a6ad04463e4cb6747e532d653ece5bcd161eec70bdff9bb24b6684b88e223e01"].pack('H*')

        Btc::Address.network_type = Btc::Address::NETWORK_TYPE_TESTNET
        inputaddr = Btc::Address.new
        privkey = Btc::Base58.check_decode('cRV7qzdRH6CqNedswy6mUoYwsCAkD4eCCDPhKCPfaCr6uhRZwQN2')
        inputaddr.privkey = privkey.last

        #check the address
        inputaddr.pubkey.should == known_pubkey
        inputaddr.address.should == known_inputaddr

        #parse the tx
        tx = Btc::Tx.new [], []
        tx.parse(tx_s)

        tx.inputs.count.should == 1

        #check the parsed input
        tx_parsed_input = tx.inputs.first
        tx_parsed_input.txid == prev_tx_s_id
        tx_parsed_input.scriptSig.should == known_scriptSig.bytesize.chr + known_scriptSig
        tx_parsed_input.index.should == 0 

        newinput = Btc::Input.new( inputaddr, prev_tx_s_id, prev_tx_s )
        newinput.scriptSig.should == prev_tx_output_scriptPubKey.bytesize.chr + prev_tx_output_scriptPubKey

        # puts "****** parsed input: #{tx_parsed_input.serialize.unpack('H*')}"
        # puts "****** new input   : #{newinput.serialize.unpack('H*')}"

        newtx = Btc::Tx.new( [newinput], tx.outputs )

        # puts "****** newtx: #{newtx.serialize.unpack('H*')}"

        # puts "****** tx_s : #{tx_s.unpack('H*')}"

        # puts "***** newtx.txhash: #{newtx.txhash.unpack('H*')}"
        txhash = newtx.txhash
        newtx.sign

        #try to verify the old sig works; i.e. is txhash correct?
        tinput = newtx.inputs.first

        sigsize = known_scriptSig.byteslice(0).ord
        tinput.sig = known_scriptSig.byteslice(1,sigsize)
        tinput.sig.should == known_sig


        # puts "****** newtx scriptSig: #{newtx.inputs.first.scriptSig.unpack('H*')}"
        # puts "****** kwntx scriptSig: #{tx_parsed_input.scriptSig.unpack('H*')}"

        tinput.verify_sig(txhash).should == true

        newtx.inputs.first.verify_sig(txhash).should == true
      end

      it 'signs a second transaction correctly' do
        # txid = ["847d89e97beb9721cb1c2159c96b82a3f9dbc1e94ca84a42a738198464be17cc"].pack('H*')
        txid = ["cc17be64841938a7424aa84ce9c1dbf9a3826bc959211ccb2197eb7be9897d84"].pack('H*')
        index = 0
        txscriptPubKey = ["76a914a85729e0303ae68f27726c9054fc4c944ec841c588ac"].pack('H*')

        output_addr = Btc::Address.new
        output_addr.set_pubkey_hash160 = ["ddaff2eb5c713ef41dd91d7fa36c4dddcf3aacb1"].pack('H*')
        input_addr = Btc::Address.new
        input_addr.compressed = false
        input_addr.privkey = ["32656870f12aa5d8c2fc9d702331dd7da2a906be072413b735a5638b625d6201"].pack('H*')

        input = Btc::Input.new( input_addr, txid, nil )
        input.set_previous( txid, index, txscriptPubKey )
        change = Btc::Output.new(input_addr,  40000)
        output = Btc::Output.new(output_addr, 50000)

        tx = Btc::Tx.new( [input], [output, change] )
        puts "****** unsigned tx: #{tx.serialize.unpack('H*')}"
        puts "****** txhash:    : #{tx.txhash.unpack('H*')}"
        tx.sign
        puts "****** signed tx: #{tx.serialize.unpack('H*')}"
        # tx.serialize.unpack('H*').should == ""
      end

      it 'signs a transaction with 2 inputs correctly' do
        #0.0012 BTC
        txid1 = ["c2dbb9692dc9d954588fc12da9ddc0f4c35336a4f30adfdb0a11a0d387167593"].pack('H*')
        index1 = 0
        txScriptPubKey1 = ["76a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988ac"].pack('H*')
        addr1_privkey = ["969c4c036314895adf916b905e288b39db5f7a9410baa541fffeaa7921b51509"].pack('H*')

        #0.0014 BTC
        txid2 = ["791858d8779802d980d1048ae8c4cae12bc30b89bcb597e2b0d6b85f06f8cdb3"].pack('H*')
        index2 = 0
        txScriptPubKey2 = ["76a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988ac"].pack('H*')
        addr2_privkey = ["969c4c036314895adf916b905e288b39db5f7a9410baa541fffeaa7921b51509"].pack('H*')

        output_addr1_pubkey_hash160 = ["b76e51e1746942095aa203f1e6a633a707d9b622"].pack('H*')
        amount1 = 110000 #0.0011
        output_addr2_pubkey_hash160 = ["d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db9"].pack('H*')
        amount2 = 140000 #0.0014
        #fee = 0.0001

        input_addr1 = Btc::Address.new
        input_addr1.compressed = false
        input_addr1.privkey = addr1_privkey
        input1 = Btc::Input.new( input_addr1, txid1, nil )
        input1.set_previous( txid1, index1, txScriptPubKey1)

        input_addr2 = Btc::Address.new
        input_addr2.compressed = false
        input_addr2.privkey = addr2_privkey
        input2 = Btc::Input.new( input_addr2, txid2, nil )
        input2.set_previous( txid2, index2, txScriptPubKey2)

        output_addr1 = Btc::Address.new
        output_addr1.set_pubkey_hash160 = output_addr1_pubkey_hash160
        output1 = Btc::Output.new( output_addr1, amount1 )

        output_addr2 = Btc::Address.new
        output_addr2.set_pubkey_hash160 = output_addr2_pubkey_hash160
        output2 = Btc::Output.new( output_addr2, amount2 )

        inputs = [input1, input2]
        outputs = [output1, output2]

        tx = Btc::Tx.new inputs, outputs

        tx.inputs.each {|i| i.zeroed = true}
        tx.inputs.each {|i| i.presig_mode = true}
        tx.txhash.unpack('H*').should == ["052cfb44717080f58766f94e73d737014c6802edab126ec5f3f843ec84642cbf"]
        tx.serialize.unpack('H*').should == ["010000000293751687d3a0110adbdf0af3a43653c3f4c0dda92dc18f5854d9c92d69b9dbc20000000000ffffffffb3cdf8065fb8d6b0e297b5bc890bc32be1cac4e88a04d180d9029877d85818790000000000ffffffff02b0ad0100000000001976a914b76e51e1746942095aa203f1e6a633a707d9b62288ace0220200000000001976a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988ac0000000001000000"]

        tx.inputs.first.zeroed = false
        tx.inputs.first.presig_mode = true
        tx.txhash.unpack('H*').should == ["594d690a845921fe52b19d4ba77dfaab5f163c0a52f7925c0d9dac8a94eae29e"]
        tx.serialize.unpack('H*').should == ["010000000293751687d3a0110adbdf0af3a43653c3f4c0dda92dc18f5854d9c92d69b9dbc2000000001976a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988acffffffffb3cdf8065fb8d6b0e297b5bc890bc32be1cac4e88a04d180d9029877d85818790000000000ffffffff02b0ad0100000000001976a914b76e51e1746942095aa203f1e6a633a707d9b62288ace0220200000000001976a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988ac0000000001000000"]

        tx.inputs.first.zeroed = true
        tx.inputs.first.presig_mode = true

        tx.inputs.last.zeroed = false
        tx.inputs.last.presig_mode = true
        tx.txhash.unpack('H*').should == ["90d2165f4da5931c29f7f4dd0d153c47dc13d14f2e05b1859f104088a3168d89"]
        tx.serialize.unpack('H*').should == ["010000000293751687d3a0110adbdf0af3a43653c3f4c0dda92dc18f5854d9c92d69b9dbc20000000000ffffffffb3cdf8065fb8d6b0e297b5bc890bc32be1cac4e88a04d180d9029877d8581879000000001976a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988acffffffff02b0ad0100000000001976a914b76e51e1746942095aa203f1e6a633a707d9b62288ace0220200000000001976a914d0ea0b77ae2d25a7ccfc0f8a669469996f8c8db988ac0000000001000000"]

      end

    end
  end

  context 'with a multisig transaction' do
    # multisig tx creation
    before do
      Btc::Address.network_type = Btc::Address::NETWORK_TYPE_MAINNET
    end

    describe '#create' do
      # case 1:
      # input - single sig
      # output - multisig (2)
      it 'creates a transaction with a multisig output' do
        #need pubkeys for these addresses
        #need txid, amount, previous_tx, prev scriptpubkey (for signature), input address key
        addr1 = Btc::Address.new
        addr1.pubkey = ["0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86"].pack('H*')
        addr2 = Btc::Address.new
        addr2.pubkey = ["04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874"].pack('H*')
        addr3 = Btc::Address.new
        addr3.pubkey = ["048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213"].pack('H*')
        redeem_script = Btc::Script::RedeemScript.new( 2, [addr1.pubkey, addr2.pubkey, addr3.pubkey])

        output_address = Btc::Address.new
        output_address.multisig_pubkey = redeem_script.redeem_script
        output_address.address.should == "3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC"

        amount = 1_000_000 # 1_000_000/100_000_000 == .01
        output = Btc::Output.new output_address, amount
        outputs = [output]

        input_address = Btc::Address.new
        txid = ["d6f72aab8ff86ff6289842a0424319bf2ddba85dc7c52757912297f948286389"].pack('H*')
        txScriptPubKey = ["76a91455c3e0412df763244b0fe23a5129cda6f606be4588ac"].pack('H*')
        input = Btc::Input.new(input_address, txid, nil)
        input.set_previous( txid, 0, txScriptPubKey)
        tx = Btc::Tx.new [input], [output]
        tx.serialize.should == ["010000000189632848f99722915727c5c75da8db2dbf194342a0429828f66ff88fab2af7d6000000001976a91455c3e0412df763244b0fe23a5129cda6f606be4588acffffffff0140420f000000000017a914f815b036d9bbbce5e9f2a00abd1bf3dc91e95510870000000001000000"].pack('H*')
        tx.txhash.should == ["ae5a372745c1acbf96e3ec84e743fb4d504bb6c2283773e8f1d7995f9665e0e3"].pack('H*')
      end

      # case 2: 
      # input - multisig
      # output - single sig
      it 'creates a tx with a multisig input and single sig output' do

        # step one - get the redeem script of the multisig input
        addr1 = Btc::Address.new
        addr1.pubkey = ["0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86"].pack('H*')
        addr1.privkey = Btc::Base58.check_decode("5JaTXbAUmfPYZFRwrYaALK48fN6sFJp4rHqq2QSXs8ucfpE4yQU").last
        addr2 = Btc::Address.new
        addr2.pubkey = ["04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874"].pack('H*')
        addr2.privkey = Btc::Base58.check_decode("5Jb7fCeh1Wtm4yBBg3q3XbT6B525i17kVhy3vMC9AqfR6FH2qGk").last
        addr3 = Btc::Address.new
        addr3.pubkey = ["048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213"].pack('H*')
        addr3.privkey = Btc::Base58.check_decode("5JFjmGo5Fww9p8gvx48qBYDJNAzR9pmH5S389axMtDyPT8ddqmw").last

        redeem_script = Btc::Script::RedeemScript.new( 2, [addr1.pubkey, addr2.pubkey, addr3.pubkey])
        redeem_script.address.should == "3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC"

        txid = ["3c9018e8d5615c306d72397f8f5eef44308c98fb576a88e030c25456b4f3a7ac"].pack('H*')
        previous_tx = nil
        index = 0

        # create a multisig input - need addresses (privkeys) and redeem script.
        #an input is a previous txid, vout.
        input = Btc::Input.new(input_address, txid, previous_tx) #input needs redeem script
        addresses = [addr1, addr2, addr3]
        addresses = [addr1]
        input.set_multisig( addresses, txid, index, redeem_script ) #init with p2sh 

        # create a normal output and amount
        amount = 1_000_000
        output = Btc::Output.new(output_address, amount)

        # create the transaction 
        tx = Btc::Tx.new [input], [output]
        tx.txhash.should == ["4d1cd2a59d8c2a544f0dba111f9cf3044abfeb5288252b0c70cb83daa790faef"].pack('H*') 
        puts "****** tx.txhash: #{tx.txhash.unpack('H*')}"
        tx.serialize.should == ["0100000001aca7f3b45654c230e0886a57fb988c3044ef5e8f7f39726d305c61d5e818903c0000000052410491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f864104865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec687441048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d4621353aeffffffff0140420f00000000001976a9141dbf6f80c4c82f3a1a4b7bb39e5bb17768a72ef188ac0000000001000000"].pack('H*') #serialization of input includes redeem script & old scriptPubKey
        puts "****** tx.serialize: #{tx.serialize.unpack('H*')}"

        # Sign it. Each input will be signed.
        #    Each address privkey will add a signature to the multisig input. 
        tx.sign #sign - needs to sign each input
        puts "****** signed tx.serialize: #{tx.serialize.unpack('H*')}"
      end

      # case 3: 
      # input - multisig
      # output - multisig

      it 'creates a tx with multisig input and multisig output' do
      end

    end


    describe '#sign' do

      it 'signs a multisig input' do
        # get a multisig transaction

        # constrcut the addresses with private keys

        # create inputs

        # sign it

        # check the outputs

      end


    end
  end
end




