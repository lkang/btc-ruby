# encoding: ASCII-8BIT
# btc_address_spec.rb
require 'spec_helper'


describe Btc::Address do 
  describe '.valid?' do
    it 'validates addresses' do
      Btc::Address.valid?('1CxHemmrdvmP3AsC3xNJHkpYS1bE9PeVb4').should == true
      Btc::Address.valid?('1FVcMfHXPp8JSCduYyELzQZf6X4tSv89ho').should == true
      Btc::Address.valid?('1HgTJED7XEGy4vVwKa8kgefWqUB3VRX2mW').should == true
      Btc::Address.valid?('1LXrSb67EaH1LGc6d6kWHq8rgv4ZBQAcpU').should == true
      Btc::Address.valid?('mj9cZ69S3RpyaN76d2eDoG8uUcXDFErKzr').should == true
      Btc::Address.valid?('184ymbnpPagDFxZX3gZKFYTWARp8vAsPL1').should == true
      Btc::Address.valid?('miZ8tdESTy1z1DcVMFECopnf96oEZFR2Q1').should == true
      #little changes create an invalid address
      Btc::Address.valid?('184ymbnpPagDFxZX3gZKFYTWARp8vAsPL1x').should == false
      Btc::Address.valid?('184ymbnpPagDxyfX3gZKFYTWARp8vAsPL1').should == false
      Btc::Address.valid?('184ymbnpPagDFxZX3gZKFYTWARp8vAsPL3').should == false
      Btc::Address.valid?('bad_address').should == false

    end
  end

  context 'with the real btc network' do
    before do
      Btc::Address.network_type = Btc::Address::NETWORK_TYPE_MAINNET
    end
    describe '#address' do
      it 'generates a valid address' do
        (0..1000).each do |i|
          baddress = Btc::Address.new
          address = baddress.address
          unless Btc::Address.valid?(address)
            puts "****** #{i}: invalid address: #{address.inspect}" 
            puts "****** address: #{Base58.decode(address).unpack('H*')}" 
            puts "****** address: #{baddress.inspect}" 
            puts "****** pubkey: #{baddress.pubkey.unpack('H*')}" 
            puts "****** pubkey_hash160: #{baddress.pubkey_hash160.unpack('H*')}" 
          end
          Btc::Address.valid?(address).should == true
        end
      end
    end

    describe '#pubkey' do 
      let(:btc_addr) { btc_addr = Btc::Address.new }

      it 'can be set to generate a different address' do
        old_address = btc_addr.address
        btc_addr.pubkey = ["0457441a4087db1d55259263585f8f12517c984c7ab09c7acf95d6095ba1835232fbf8b6817b06a96c12e925e9e2e35dd19046f5871458bf359b9215c654ea0b2a"].pack('H*')
        address = btc_addr.address
        address.should_not == old_address
        btc_addr.compressed.should == false
        address.should == '1PTLR1TsAbz4Hmr6Qpg4LZ3LewpvQSUvVm'
      end
    end

    describe '#privkey=' do
      let(:btc_addr) { btc_addr = Btc::Address.new }

      it 'generates a new compressed pubkey and address after being set (case 0)' do
        btc_addr.privkey = "\x11Xr>\xD1\xC6\x87\xCA\x1E\xE3\xA1\xCD\x03\xEFn\e\xA1!\xAA\xDD\xA1Rm\xDE\xEB\x11\x96\xB8\xD5\xB3\f\xBA" + "\x01"
        btc_addr.pubkey.should == "\x03\xC3\f\aF\xE0O\x04a4\xFF\xAB28\xFFI\xDFT\#@3\x06\x82\xDFJiv<i.\x06\xB3y"
        btc_addr.address.should == "17qYgi4NyKUwaxxTD7VLYzokXu3rjzL2Lc"
        btc_addr.pubkey_hash160.should == ["4aff2b7bb7715e46ae65275430d47d760997e196"].pack('H*')
      end

      it 'generates a new pubkey and address after being set (case 0)' do
        btc_addr.privkey = "\x11Xr>\xD1\xC6\x87\xCA\x1E\xE3\xA1\xCD\x03\xEFn\e\xA1!\xAA\xDD\xA1Rm\xDE\xEB\x11\x96\xB8\xD5\xB3\f\xBA"
        btc_addr.pubkey.should == "\x04\xC3\f\aF\xE0O\x04a4\xFF\xAB28\xFFI\xDFT\#@3\x06\x82\xDFJiv<i.\x06\xB3y%\xB1\xE1\x15+\xB0\x06s\xC5\x11\nm\xC79\x86Cr\xBDx7\n\xA3d\xF9\xD8\f\xAA\tm\x15\xC8\x95" 
        btc_addr.address.should == "1GTTFckrqFQK1rdN2uiYNP84Rt6Tke4qsS"
      end

      it 'generates a new uncompressed pubkey and address after being set (case1)' do
        btc_addr.privkey = ["1111111111111111111111111111111111111111111111111111111111111111"].pack('H*')
        btc_addr.pubkey.should == ["044f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa385b6b1b8ead809ca67454d9683fcf2ba03456d6fe2c4abe2b07f0fbdbb2f1c1"].pack('H*')
        btc_addr.address.should == '1MsHWS1BnwMc3tLE8G35UXsS58fKipzB7a'
      end

      it 'generates a new compressed pubkey and address after being set (case1)' do
        btc_addr.privkey = ["111111111111111111111111111111111111111111111111111111111111111101"].pack('H*')
        btc_addr.pubkey.should == ["034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa"].pack('H*')
        btc_addr.address.should == '1Q1pE5vPGEEMqRcVRMbtBK842Y6Pzo6nK9'
        btc_addr.pubkey_hash160.should == ["fc7250a211deddc70ee5a2738de5f07817351cef"].pack('H*')
      end

      it 'generates a new uncompressed pubkey and address after being set (case2)' do
        btc_addr.privkey = ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"].pack('H*')
        btc_addr.pubkey.should == ["04ed83704c95d829046f1ac27806211132102c34e9ac7ffa1b71110658e5b9d1bdedc416f5cefc1db0625cd0c75de8192d2b592d7e3b00bcfb4a0e860d880fd1fc"].pack('H*')
        btc_addr.address.should == '1JyMKvPHkrCQd8jQrqTR1rBsAd1VpRhTiE'
      end

      it 'generates a new compressed pubkey and address after being set (case2)' do
        btc_addr.privkey = ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd01"].pack('H*')
        btc_addr.pubkey.should == ["02ed83704c95d829046f1ac27806211132102c34e9ac7ffa1b71110658e5b9d1bd"].pack('H*')
        btc_addr.address.should == '1NKRhS7iYUGTaAfaR5z8BueAJesqaTyc4a'
      end

      it 'generates a new uncompressed pubkey and address after being set (case3)' do
        btc_addr.privkey = ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b012"].pack('H*')
        btc_addr.pubkey.should == ["042596957532fc37e40486b910802ff45eeaa924548c0e1c080ef804e523ec3ed3ed0a9004acf927666eee18b7f5e8ad72ff100a3bb710a577256fd7ec81eb1cb3"].pack('H*')
        btc_addr.address.should == '1PM35qz2uwCDzcUJtiqDSudAaaLrWRw41L'
      end

      it 'generates a new compressed pubkey and address after being set (case3)' do
        btc_addr.privkey = ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b01201"].pack('H*')
        btc_addr.pubkey.should == ["032596957532fc37e40486b910802ff45eeaa924548c0e1c080ef804e523ec3ed3"].pack('H*')
        btc_addr.address.should == '19ck9VKC6KjGxR9LJg4DNMRc45qFrJguvV'
        btc_addr.pubkey_hash160.should == ["5e8394e9a49a9ae155b4ac5d68e39ab8bacaa37e"].pack('H*')
      end
    end

    describe '#set_pubkey_hash160' do
      let(:btc_addr) { btc_addr = Btc::Address.new }

      it 'sets pubkey_hash160 and generates the correct btc address' do
        btc_addr.set_pubkey_hash160 = ["5e8394e9a49a9ae155b4ac5d68e39ab8bacaa37e"].pack('H*')
        btc_addr.address.should == '19ck9VKC6KjGxR9LJg4DNMRc45qFrJguvV'
      end

      it 'sets pubkey_hash160 and generates the correct btc address' do
        btc_addr.set_pubkey_hash160 = ["fc7250a211deddc70ee5a2738de5f07817351cef"].pack('H*')
        btc_addr.address.should == '1Q1pE5vPGEEMqRcVRMbtBK842Y6Pzo6nK9'
      end

      it 'sets pubkey_hash160 and generates the correct btc address' do
        btc_addr.set_pubkey_hash160 = ["4aff2b7bb7715e46ae65275430d47d760997e196"].pack('H*')
        btc_addr.address.should == "17qYgi4NyKUwaxxTD7VLYzokXu3rjzL2Lc"
      end
    end

    context 'with a multisig address' do
      let(:redeem_script) do
        Btc::Script::RedeemScript.new( 2, [["03d06e98ecb432ba143ace42b3eaebdb543066060f074c01bc37a6fa5fb7275011"].pack('H*'), ["03e585cfe1a6db8262f5152e994380a6b364b4767170403d48554880fd102896c3"].pack('H*')])
      end

      it 'creates a valid multisig address' do
        a = Btc::Address.new
        a.multisig_pubkey = redeem_script.redeem_script
        a.address.should == '3Lp2VYmLy6biADreJQ3MuXwFmDTWQZxdwB'
      end
    end
  end


  context 'with the test network' do
    before do
      Btc::Address.network_type = Btc::Address::NETWORK_TYPE_TESTNET
    end
    describe '#address' do
      it 'generates a valid address' do
        (0..1000).each do |i|
          baddress = Btc::Address.new
          address = baddress.address
          unless Btc::Address.valid?(address)
            puts "****** #{i}: invalid address: #{address.inspect}" 
            puts "****** address: #{Base58.decode(address).unpack('H*')}" 
            puts "****** address: #{baddress.inspect}" 
            puts "****** pubkey: #{baddress.pubkey.unpack('H*')}" 
            puts "****** pubkey_hash160: #{baddress.pubkey_hash160.unpack('H*')}" 
          end

          Btc::Address.valid?(address).should == true
        end
      end
    end

    describe '#pubkey' do 
      let(:btc_addr) { btc_addr = Btc::Address.new }

      it 'can be set to generate a different address' do
        old_address = btc_addr.address
        btc_addr.pubkey = ["0457441a4087db1d55259263585f8f12517c984c7ab09c7acf95d6095ba1835232fbf8b6817b06a96c12e925e9e2e35dd19046f5871458bf359b9215c654ea0b2a"].pack('H*')
        address = btc_addr.address
        address.should_not == old_address
        btc_addr.compressed.should == false
        address.should == 'n3yHi4YqydRK4tKi8PeSAUFfWwRdERiGHn'
      end
    end

    describe '#privkey=' do
      let(:btc_addr) { btc_addr = Btc::Address.new }

      it 'generates a new compressed pubkey and address after being set (case 0)' do
        btc_addr.privkey = "\x11Xr>\xD1\xC6\x87\xCA\x1E\xE3\xA1\xCD\x03\xEFn\e\xA1!\xAA\xDD\xA1Rm\xDE\xEB\x11\x96\xB8\xD5\xB3\f\xBA" + "\x01"
        btc_addr.pubkey.should == "\x03\xC3\f\aF\xE0O\x04a4\xFF\xAB28\xFFI\xDFT\#@3\x06\x82\xDFJiv<i.\x06\xB3y"
        btc_addr.address.should == "mnMVym9MnLvCN5S4vgTiNv25PteZguKGAw"
      end

      it 'generates a new pubkey and address after being set (case 0)' do
        btc_addr.privkey = "\x11Xr>\xD1\xC6\x87\xCA\x1E\xE3\xA1\xCD\x03\xEFn\e\xA1!\xAA\xDD\xA1Rm\xDE\xEB\x11\x96\xB8\xD5\xB3\f\xBA"
        btc_addr.pubkey.should == "\x04\xC3\f\aF\xE0O\x04a4\xFF\xAB28\xFFI\xDFT\#@3\x06\x82\xDFJiv<i.\x06\xB3y%\xB1\xE1\x15+\xB0\x06s\xC5\x11\nm\xC79\x86Cr\xBDx7\n\xA3d\xF9\xD8\f\xAA\tm\x15\xC8\x95" 
        btc_addr.address.should == "mvyQYfqqeGqZny6ykUgvCJLPHshAhnhhFe"
      end

      it 'generates a new uncompressed pubkey and address after being set (case1)' do
        btc_addr.privkey = ["1111111111111111111111111111111111111111111111111111111111111111"].pack('H*')
        btc_addr.pubkey.should == ["044f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa385b6b1b8ead809ca67454d9683fcf2ba03456d6fe2c4abe2b07f0fbdbb2f1c1"].pack('H*')
        btc_addr.address.should == 'n2PEoV6Abxnrpzoqqq1TJT5kw8G2dMPpBd'
      end

      it 'generates a new compressed pubkey and address after being set (case1)' do
        btc_addr.privkey = ["111111111111111111111111111111111111111111111111111111111111111101"].pack('H*')
        btc_addr.pubkey.should == ["034f355bdcb7cc0af728ef3cceb9615d90684bb5b2ca5f859ab0f0b704075871aa"].pack('H*')
        btc_addr.address.should == 'n4XmX91N5FfccY678vaG1ELNtXh6skVES7'
      end

      it 'generates a new uncompressed pubkey and address after being set (case2)' do
        btc_addr.privkey = ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"].pack('H*')
        btc_addr.pubkey.should == ["04ed83704c95d829046f1ac27806211132102c34e9ac7ffa1b71110658e5b9d1bdedc416f5cefc1db0625cd0c75de8192d2b592d7e3b00bcfb4a0e860d880fd1fc"].pack('H*')
        btc_addr.address.should == 'myVJcyUGZsdfQFD2aQRnqmQC2ccChFzKVe'
      end

      it 'generates a new compressed pubkey and address after being set (case2)' do
        btc_addr.privkey = ["dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd01"].pack('H*')
        btc_addr.pubkey.should == ["02ed83704c95d829046f1ac27806211132102c34e9ac7ffa1b71110658e5b9d1bd"].pack('H*')
        btc_addr.address.should == 'n2qNzVChMVhiMH9C8exW1prVAeUYS3w8sE'
      end

      it 'generates a new uncompressed pubkey and address after being set (case3)' do
        btc_addr.privkey = ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b012"].pack('H*')
        btc_addr.pubkey.should == ["042596957532fc37e40486b910802ff45eeaa924548c0e1c080ef804e523ec3ed3ed0a9004acf927666eee18b7f5e8ad72ff100a3bb710a577256fd7ec81eb1cb3"].pack('H*')
        btc_addr.address.should == 'n3rzNu51ixdUmiwvcHobGpqVSZwZUPxD4C'
      end

      it 'generates a new compressed pubkey and address after being set (case3)' do
        btc_addr.privkey = ["47f7616ea6f9b923076625b4488115de1ef1187f760e65f89eb6f4f7ff04b01201"].pack('H*')
        btc_addr.pubkey.should == ["032596957532fc37e40486b910802ff45eeaa924548c0e1c080ef804e523ec3ed3"].pack('H*')
        btc_addr.address.should == 'mp8hSYQAuMAXjXcx2F2bCGdvv5RxmK6R9M'
      end
    end

    context 'with a multisig address' do
      let(:addr1) do
        a = Btc::Address.new
        a.compressed = false
        a.privkey = ["b62bc24e8bbe9757bd1de678449dc7b8386b608c3bcf5f41b5e8e41324890828"].pack('H*')
        a.pubkey = ["04d06e98ecb432ba143ace42b3eaebdb543066060f074c01bc37a6fa5fb72750115538a09e5f774e871d7ec7a366e748007f666d8d61325a41ef331e022e74be9b"].pack('H*')
        a.compressed = true
        a
      end

      let(:addr2) do
        a = Btc::Address.new
        a.compressed = false
        a.privkey = ["d0befca52fc8984078d1a929f6db502cb403f442920e64c0d680bacb71b5ddbe"].pack('H*')
        a.pubkey = ["04e585cfe1a6db8262f5152e994380a6b364b4767170403d48554880fd102896c3ffad76cd6905164435a1aa705c0334dcf25078dd2ed60468633173d2d027f383"].pack('H*')
        a.compressed = true
        a
      end

      let(:redeem_script) do
        Btc::Script::RedeemScript.new( 2, [addr1.pubkey, addr2.pubkey])
      end

      it 'creates a valid multisig address' do
        a = Btc::Address.new
        a.multisig_pubkey = redeem_script.redeem_script
        a.address.should == '2NCNEZHhNaZ74N1VByXfEXUvWyZfgDcxTq5'
      end
    end
  end
end




