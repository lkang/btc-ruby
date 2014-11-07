# tx.rb

# create a transaction structure

module Btc
# class Btc::StandardTx < Btc::Tx
  class Tx
    include Types

    attr_accessor :inputs, :outputs, :presig_mode, :version, :lock_time

    def initialize(inputs, outputs, presig_mode=true)
      self.presig_mode = presig_mode
      self.inputs = inputs
      self.outputs = outputs
    end

    def serialize
      version +
      to_varint( inputs.count ) +
      inputs.map(&:serialize).join +
      to_varint( outputs.count ) +
      outputs.map(&:serialize).join +
      lock_time +
      hashtype
    end

    def version
      to_uint32_a( @version || 1 )
    end

    def hashtype
      presig_mode ? to_uint32_a(1) : ""
    end

    def lock_time
      # if non-zero and sequence numbers are < 0xFFFFFFFF: block height or timestamp when transaction is final  
      to_uint32_a( @locktime || 0 )
    end

    def txhash
      txhash = OpenSSL::Digest::SHA256.digest(OpenSSL::Digest::SHA256.digest(serialize)) #with a hash
    end

    def sign
      self.presig_mode = true

      inputs.each { |input| input.zeroed = true }

      inputs.each do |input|
        input.zeroed = false
        input.presig_mode = true #the input needs to inject the pubkey of the prev tx
        signable_hash = txhash
        puts "****** seriaized: #{serialize.unpack('H*')}"
        puts "****** signable_hash: #{signable_hash.unpack('H*')}"
        input.sign(signable_hash)
        input.zeroed = true
      end

      inputs.each { |input| input.zeroed = false }

      self.presig_mode = false
    end

    def parse(s)
      @ser = s
      # version +
      self.version = to_uint32(s.byteslice(0..3))

      # in_counter +
      in_counter = s.byteslice(4).unpack('C').first

      # list_of_inputs +
      self.inputs = []
      s = s.byteslice(5..-1)
      # puts "****** in_counter: #{in_counter}"
      # puts "****** s: #{s.unpack('H*')}"
      self.inputs = (0..in_counter-1).inject([]) do |sum, i|
        new_input = Input.new( Btc::Address.new, nil, nil )
        s = new_input.parse(s)
        # puts "****** new_input: #{new_input.inspect}"
        sum += [new_input]
      end

      # out_counter + 
      out_counter = s.byteslice(0).unpack('C').first

      s = s.byteslice(1..-1)
      # puts "****** out_counter: #{out_counter}"
      # puts "****** s: #{s.unpack('H*')}"
     # list_of_outputs +
      self.outputs = (0..out_counter-1).inject([]) do |sum, i|
        new_output = Output.new(nil, nil)
        s = new_output.parse(s)
        sum += [new_output]
      end
      # lock_time

      self.lock_time = to_uint32(s.byteslice(-4..-1))
    end
  end
end
