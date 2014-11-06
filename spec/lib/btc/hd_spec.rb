# hd_spec.rb
require 'spec_helper'

describe Btc::Hd::ExtendedKey do
  describe '#deserialize' do
    it 'deserializes an extended key' do
      ek = Btc::Hd::ExtendedKey.new

      ek.deserialize 'xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8'

      ek.keytype.should == Btc::Hd::ExtendedKey::PUBLIC_KEY
      ek.depth.should == 0
      ek.child_number.should == 0

      ek.chain_code.unpack('H*').should == ["873dff81c02f525623fd1fe5167eac3a55a049de3d314bb42ee227ffed37d508"]
      ek.key.unpack('H*').should == ["0339a36013301597daef41fbe593a02cc513d0b55527ec2df1050e2e8ff49c85c2"]
    end
  end

  describe '#master' do
    let(:ek) { Btc::Hd::ExtendedKey.new }

    it 'seeds the master node (test vector 1)' do
      ek.master(["000102030405060708090a0b0c0d0e0f"].pack('H*'))
      ek.serialize.should == 'xprv9s21ZrQH143K3QTDL4LXw2F7HEK3wJUD2nW2nRk4stbPy6cq3jPPqjiChkVvvNKmPGJxWUtg6LnF5kejMRNNU3TGtRBeJgk33yuGBxrMPHi'
      public_ek = ek.ckd_public
      public_ek.serialize.should == 'xpub661MyMwAqRbcFtXgS5sYJABqqG9YLmC4Q1Rdap9gSE8NqtwybGhePY2gZ29ESFjqJoCu1Rupje8YtGqsefD265TMg7usUDFdp6W1EGMcet8'
    end

    it 'seeds the master node (test vector 2)' do
      ek.master(["fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"].pack('H*'))
      ek.serialize.should == 'xprv9s21ZrQH143K31xYSDQpPDxsXRTUcvj2iNHm5NUtrGiGG5e2DtALGdso3pGz6ssrdK4PFmM8NSpSBHNqPqm55Qn3LqFtT2emdEXVYsCzC2U'
      public_ek = ek.ckd_public
      public_ek.serialize.should == 'xpub661MyMwAqRbcFW31YEwpkMuc5THy2PSt5bDMsktWQcFF8syAmRUapSCGu8ED9W6oDMSgv6Zz8idoc4a6mr8BDzTJY47LJhkJ8UB7WEGuduB'
    end
  end

  describe '#ckd_private' do
    let(:ek) { Btc::Hd::ExtendedKey.new }

    it 'finds the 0th hard key (test vector 1)' do
      ek.master(["000102030405060708090a0b0c0d0e0f"].pack('H*'))
      m0h = ek.ckd_private( 0 + 2**31 )
      m0h.serialize.should == 'xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7'

      sk = Btc::Hd::ExtendedKey.new
      sk.deserialize 'xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7'
      m0h.key.unpack('H*').should == sk.key.unpack('H*')
      m0h.chain_code.unpack('H*').should == sk.chain_code.unpack('H*')  
      m0h.depth == sk.depth 
      m0h.keytype.should == sk.keytype
      m0h.child_number.should == sk.child_number

      m0h1 = m0h.ckd_private(1)

      sk = Btc::Hd::ExtendedKey.new
      sk.deserialize 'xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs'
      m0h1.key.unpack('H*').should == sk.key.unpack('H*')
      m0h1.chain_code.unpack('H*').should == sk.chain_code.unpack('H*')  
      m0h1.depth == sk.depth 
      m0h1.keytype.should == sk.keytype
      m0h1.fingerprint.unpack('H*').should == sk.parent_fingerprint.unpack('H*')
      m0h1.child_number.should == sk.child_number

      m0h1.serialize.should == 'xprv9wTYmMFdV23N2TdNG573QoEsfRrWKQgWeibmLntzniatZvR9BmLnvSxqu53Kw1UmYPxLgboyZQaXwTCg8MSY3H2EU4pWcQDnRnrVA1xe8fs'

      m0h12h = m0h1.ckd_private(2 + 2**31)
      m0h12h.serialize.should == 'xprv9z4pot5VBttmtdRTWfWQmoH1taj2axGVzFqSb8C9xaxKymcFzXBDptWmT7FwuEzG3ryjH4ktypQSAewRiNMjANTtpgP4mLTj34bhnZX7UiM'

      m0h12h2 = m0h12h.ckd_private(2)
      m0h12h2.serialize.should == 'xprvA2JDeKCSNNZky6uBCviVfJSKyQ1mDYahRjijr5idH2WwLsEd4Hsb2Tyh8RfQMuPh7f7RtyzTtdrbdqqsunu5Mm3wDvUAKRHSC34sJ7in334'

      m0h12h21000000000 = m0h12h2.ckd_private(1000000000)
      m0h12h21000000000.serialize.should == 'xprvA41z7zogVVwxVSgdKUHDy1SKmdb533PjDz7J6N6mV6uS3ze1ai8FHa8kmHScGpWmj4WggLyQjgPie1rFSruoUihUZREPSL39UNdE3BBDu76'
    end

    it 'finds the 0th key (test vector 2)' do
      ek.master(["fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"].pack('H*'))
      m0 = ek.ckd_private( 0 )
      m0.serialize.should == 'xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt'

      sk = Btc::Hd::ExtendedKey.new
      sk.deserialize 'xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt'
      m0.key.unpack('H*').should == sk.key.unpack('H*')
      m0.chain_code.unpack('H*').should == sk.chain_code.unpack('H*')  
      m0.depth == sk.depth 
      m0.keytype.should == sk.keytype
      m0.fingerprint.unpack('H*').should == sk.parent_fingerprint.unpack('H*')
      m0.child_number.should == sk.child_number

      m02147483647h = m0.ckd_private(2147483647 + 2**31)
      m02147483647h.serialize.should == 'xprv9wSp6B7kry3Vj9m1zSnLvN3xH8RdsPP1Mh7fAaR7aRLcQMKTR2vidYEeEg2mUCTAwCd6vnxVrcjfy2kRgVsFawNzmjuHc2YmYRmagcEPdU9'

      m02147483647h1 = m02147483647h.ckd_private(1)
      m02147483647h1.serialize.should == 'xprv9zFnWC6h2cLgpmSA46vutJzBcfJ8yaJGg8cX1e5StJh45BBciYTRXSd25UEPVuesF9yog62tGAQtHjXajPPdbRCHuWS6T8XA2ECKADdw4Ef'

      m02147483647h12147483646h = m02147483647h1.ckd_private(2147483646 + 2**31)
      m02147483647h12147483646h.serialize.should == 'xprvA1RpRA33e1JQ7ifknakTFpgNXPmW2YvmhqLQYMmrj4xJXXWYpDPS3xz7iAxn8L39njGVyuoseXzU6rcxFLJ8HFsTjSyQbLYnMpCqE2VbFWc'

      m02147483647h12147483646h2 = m02147483647h12147483646h.ckd_private(2)
      m02147483647h12147483646h2.serialize.should == 'xprvA2nrNbFZABcdryreWet9Ea4LvTJcGsqrMzxHx98MMrotbir7yrKCEXw7nadnHM8Dq38EGfSh6dqA9QWTyefMLEcBYJUuekgW4BYPJcr9E7j'
    end
  end

  describe '#ckd_public' do
    let(:ek) { Btc::Hd::ExtendedKey.new }

    it 'derives the public key chain (test vector 1)' do
      ek.master(["000102030405060708090a0b0c0d0e0f"].pack('H*'))
      m = ek
      cM = ek.ckd_public

      m0h = ek.ckd_private( 0 + 2**31 )
      m0h.serialize.should == 'xprv9uHRZZhk6KAJC1avXpDAp4MDc3sQKNxDiPvvkX8Br5ngLNv1TxvUxt4cV1rGL5hj6KCesnDYUhd7oWgT11eZG7XnxHrnYeSvkzY7d2bhkJ7'
 
      cm0h = m0h.ckd_public #cm is Capital M
      cm0h.serialize.should == 'xpub68Gmy5EdvgibQVfPdqkBBCHxA5htiqg55crXYuXoQRKfDBFA1WEjWgP6LHhwBZeNK1VTsfTFUHCdrfp1bgwQ9xv5ski8PX9rL2dZXvgGDnw'
      expect{ cM.ckd_public( 0 + 2**31 ) }.to raise_error('cannot generate hardened public key from public key')

      cm0h1 = cm0h.ckd_public(1)
      cm0h1.serialize.should == 'xpub6ASuArnXKPbfEwhqN6e3mwBcDTgzisQN1wXN9BJcM47sSikHjJf3UFHKkNAWbWMiGj7Wf5uMash7SyYq527Hqck2AxYysAA7xmALppuCkwQ'
  
      expect { cm0h1.ckd_public(2 + 2**31) }.to raise_error('cannot generate hardened public key from public key')

      cm0h12h = m0h.ckd_private(1).ckd_private(2 + 2**31).ckd_public
      cm0h12h.serialize.should == 'xpub6D4BDPcP2GT577Vvch3R8wDkScZWzQzMMUm3PWbmWvVJrZwQY4VUNgqFJPMM3No2dFDFGTsxxpG5uJh7n7epu4trkrX7x7DogT5Uv6fcLW5'

      cm0h12h2 = cm0h12h.ckd_public(2)
      cm0h12h2.serialize.should == 'xpub6FHa3pjLCk84BayeJxFW2SP4XRrFd1JYnxeLeU8EqN3vDfZmbqBqaGJAyiLjTAwm6ZLRQUMv1ZACTj37sR62cfN7fe5JnJ7dh8zL4fiyLHV'

      cm0h12h21000000000 = cm0h12h2.ckd_public(1000000000)
      cm0h12h21000000000.serialize.should == 'xpub6H1LXWLaKsWFhvm6RVpEL9P4KfRZSW7abD2ttkWP3SSQvnyA8FSVqNTEcYFgJS2UaFcxupHiYkro49S8yGasTvXEYBVPamhGW6cFJodrTHy'
    end

    it 'derives the public key chain (test vector 2)' do
      ek.master(["fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542"].pack('H*'))
      m = ek
      cM = ek.ckd_public

      m0 = ek.ckd_private( 0 )
      m0.serialize.should == 'xprv9vHkqa6EV4sPZHYqZznhT2NPtPCjKuDKGY38FBWLvgaDx45zo9WQRUT3dKYnjwih2yJD9mkrocEZXo1ex8G81dwSM1fwqWpWkeS3v86pgKt'
      cM0 = cM.ckd_public( 0 )
      cM0.serialize.should == 'xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH'

      cm0 = m0.ckd_public #cm is Capital M
      cm0.serialize.should == 'xpub69H7F5d8KSRgmmdJg2KhpAK8SR3DjMwAdkxj3ZuxV27CprR9LgpeyGmXUbC6wb7ERfvrnKZjXoUmmDznezpbZb7ap6r1D3tgFxHmwMkQTPH'

      expect { cM0.ckd_public(2147483647 + 2**31) }.to raise_error 'cannot generate hardened public key from public key'
      cM02147483647h = m0.ckd_private(2147483647 + 2**31).ckd_public
      cM02147483647h.serialize.should == 'xpub6ASAVgeehLbnwdqV6UKMHVzgqAG8Gr6riv3Fxxpj8ksbH9ebxaEyBLZ85ySDhKiLDBrQSARLq1uNRts8RuJiHjaDMBU4Zn9h8LZNnBC5y4a'

      cM02147483647h1 = cM02147483647h.ckd_public(1)
      cM02147483647h1.serialize.should == 'xpub6DF8uhdarytz3FWdA8TvFSvvAh8dP3283MY7p2V4SeE2wyWmG5mg5EwVvmdMVCQcoNJxGoWaU9DCWh89LojfZ537wTfunKau47EL2dhHKon'

      expect { cM02147483647h1.ckd_public(2147483646 + 2**31) }.to raise_error 'cannot generate hardened public key from public key'
      cM02147483647h12147483646h = m0.ckd_private(2147483647 + 2**31).ckd_private(1).ckd_private(2147483646 + 2**31).ckd_public
      cM02147483647h12147483646h.serialize.should == 'xpub6ERApfZwUNrhLCkDtcHTcxd75RbzS1ed54G1LkBUHQVHQKqhMkhgbmJbZRkrgZw4koxb5JaHWkY4ALHY2grBGRjaDMzQLcgJvLJuZZvRcEL'

      cM02147483647h12147483646h2 = cM02147483647h12147483646h.ckd_public(2)
      cM02147483647h12147483646h2.serialize.should == 'xpub6FnCn6nSzZAw5Tw7cgR9bi15UV96gLZhjDstkXXxvCLsUXBGXPdSnLFbdpq8p9HmGsApME5hQTZ3emM2rnY5agb9rXpVGyy3bdW6EEgAtqt'
    end
  end

end


