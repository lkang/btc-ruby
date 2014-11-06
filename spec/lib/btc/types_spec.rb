# encoding: ASCII-8BIT
# types_spec.rb
require 'spec_helper'

describe Btc::Types do 
  let(:tt) do
    class TypesTester
      include Btc::Types
    end
    TypesTester.new
  end

  describe '#to_varint' do
    it 'creates a varint from an 8 bit number' do
      tt.to_varint( 129 ).should == ["81"].pack('H*')
    end

    it 'creates a varint from a 16 bit number' do
      tt.to_varint( 384 ).should == ["fd8001"].pack('H*')
    end

    it 'creates a varint from a 32 bit number' do
      tt.to_varint( 384 << 16 ).should == ["fe00008001"].pack('H*')
    end

    it 'creates a varint from a 64 bit number' do
      tt.to_varint( 384 << 48 ).should == ["ff0000000000008001"].pack('H*')
    end
  end

  describe '#to_vint' do
    it 'converts a byte array into an 8 bit number' do
      v, r = tt.to_vint(["81123456"].pack('H*'))
      v.should == 129
      r.should == "\x12\x34\x56"
    end

    it 'converts a byte array into an 8 bit number' do
      v, r = tt.to_vint(["fd8001123456"].pack('H*'))
      v.should == 384
      r.should == "\x12\x34\x56"
    end

    it 'converts a byte array into an 8 bit number' do
      v, r = tt.to_vint(["fe00008001123456"].pack('H*'))
      v.should == 384 << 16
      r.should == "\x12\x34\x56"
    end

    it 'converts a byte array into an 8 bit number' do
      v, r = tt.to_vint(["ff0000000000008001123456"].pack('H*'))
      v.should == 384 << 48
      r.should == "\x12\x34\x56"
    end
  end
end