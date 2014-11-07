# merkle.rb

# t = MerkleTree.new
# t.blocks = [ '1',  '2', '3' ]
# t.root # => 'the root of the merkle tree'
# 
class Btc::MerkleTree
  attr_accessor :blocks

  def dSHA256( h )
    OpenSSL::Digest::SHA256.digest OpenSSL::Digest::SHA256.digest h
  end

  def root
    new_level = base
    while new_level.count > 1 do
      base_level = new_level
      new_level = level( base_level )
    end
    new_level.first
  end

  def level( base_level )
    return base_level if base_level.count == 1

    if base_level.count % 2 == 1
      base_level << base_level.last
    end

    new_level = []
    (0..(base_level.count/2)-1).each do |i|
      new_level << dSHA256( base_level[i*2] + base_level[i*2+1] )
    end
    new_level
  end

  def base 
    l1 = blocks.inject([]) do |sum, block|
      sum << dSHA256( block )
      sum
    end
  end
end
