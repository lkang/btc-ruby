# coind_api.rb
class CoindApi

  def self.sequence
    @sequence = 0 if @sequence.nil? 
    @sequence += 1
  end

  def server_url
    'someserver'
  end

  def auth
    { 
      username: 'someuser',
      password: 'somepassword'
    }
  end

  def header
    {
      'Content-Type' => 'application/json'
    }
  end

  def request(command)
    begin
      puts "****** get request to: #{server_url.inspect}"
      command[:id] = self.class.sequence
      response = HTTParty.get(
        server_url, {
          :body => command.to_json, 
          :headers => header, 
          :basic_auth => auth
        })
      raise "internal request error"                     if response.nil?
      raise "no parsed response"                         if !response.respond_to? :parsed_response
      if response.code != 200
        puts "response: #{response.parsed_response.inspect}"
        raise response.parsed_response['error']['message'] #if response.code != 200
      end
      raise response.parsed_response['error']['message'] if response.parsed_response['result'].nil?
      response.parsed_response
    rescue => ex
      Rails.logger.error("Failed #{self.class.name} request: ex: #{ex.inspect} command: #{command.inspect}")
      raise "internal connection error" if ex.class == Errno::ECONNREFUSED
      raise
    end
  end

  # get balance for an account
  def getbalance(account=nil)
    { 
      method: :getbalance, 
      params: account ? [account.to_s] : []
    }
  end

  #find the addresses associated with this account
  def getaddressesbyaccount(account)
    {
      method: :getaddressesbyaccount, 
      params:[account.to_s]
    }
  end

  #create an account
  def getaccountaddress(account)
    {
      method: :getaccountaddress, 
      params:[account.to_s]
    }
  end

  def getblockcount
    {
      method: :getblockcount, 
      params:[]
    }
  end

  def getblock(hash)
    {
      method: :getblock,
      params:[hash]
    }
  end

  def getblockhash(index)
    {
      method: :getblockhash,
      params:[index]
    }
  end

  def listaccounts
    {
      method: :listaccounts, 
      params:[] 
    }
  end

  # move funds from one account to another
  def move( from_account, to_account, amount, minconf=1, comment='' )
    {
      method: :move,
      params: [from_account, to_account, amount, minconf, comment]
    }
  end

  # move funds from an account to an address
  def sendfrom( from_account, to_address, amount )
    {
      method: :sendfrom,
      params: [from_account, to_address, amount]
    }
  end

  def validateaddress( addr )
    {
      method: :validateaddress,
      params:[addr]
    }
  end

  def listreceivedbyaccount( minconf=1, includeempty=false )
    {
      method: :listreceivedbyaccount,
      params:[minconf, includeempty]
    }
  end

  def listreceivedbyaddress( minconf=1, includeempty=false )
    {
      method: :listreceivedbyaddress,
      params:[minconf, includeempty]
    }
  end

  def listtransactions( account, count=10, from=0 )
    {
      method: :listtransactions,
      params:[account, count, from]
    }
  end

  def getrawtransaction( txid, verbose=0 )
    {
      method: :getrawtransaction,
      params:[txid, verbose]
    }
  end

  def dumpprivkey( addr )
    {
      method: :dumpprivkey,
      params:[addr]
    }
  end

  def getreceivedbyaddress( addr, minconf=1 )
    {
      method: :getreceivedbyaddress,
      params:[addr, minconf]
    }
  end

  def getreceivedbyaccount( account='', minconf=1 )
    {
      method: :getreceivedbyaccount,
      params:[account, minconf]
    }
  end

  def validateaddress( addr )
    {
      method: :validateaddress,
      params:[addr]
    }
  end

  def verifymessage( addr, signature, message )
    {
      method: :verifymessage,
      params:[addr, signature, message]
    }
  end

  def submitblock( hexdata, optional_params_obj )
    {
      method: :submitblock,
      params:[hexdata, optional_params_obj]
    }
  end

  # Submits raw transaction (serialized, hex-encoded) to local node and network.   N
  def sendrawtransaction( hexstring )
    {
      method: :sendrawtransaction,
      params:[hexstring]
    }
  end

  # sendtoaddress  <bitcoinaddress> <amount> [comment] [comment-to]  <amount> is a real and is rounded to 8 decimal places. Returns the transaction ID <txid> if successful.   Y
  def sendtoaddress( bitcoinaddress, amount, comment='', comment_to='' )
    {
      method: :sendtoaddress,
      params:[bitcoinaddress, amount, comment, comment_to]
    }
  end

  # setaccount   <bitcoinaddress> <account>  Sets the account associated with the given address. Assigning address that is already assigned to the same account will create a new address associated with that account.  N
  def setaccount( bitcoinaddress, account )
    {
      method: :setaccount,
      params:[bitcoinaddress, account]
    }
  end

  # setgenerate  <generate> [genproclimit]   <generate> is true or false to turn generation on or off.
  def setgenerate( generate, genproclimit=1 )
    {
      method: :setgenerate,
      params:[generate, genproclimit]
    }
  end

  # settxfee   <amount>  <amount> is a real and is rounded to the nearest 0.00000001   N
  def settxfee( amount )
    {
      method: :settxfee,
      params:[amount]
    }
  end

  # signmessage  <bitcoinaddress> <message>  Sign a message with the private key of an address
  def signmessage(bitcoinaddress, message)
    {
      method: :signmessage,
      params:[bitcoinaddress, message]
    }
  end    

  # signrawtransaction   <hexstring> [{"txid":txid,"vout":n,"scriptPubKey":hex},...] [<privatekey1>,...]
  def signrawtransaction( hexstring, inputs, privatekeys )
    {
      method: :signrawtransaction,
      params:[hexstring, inputs, privatekeys]
    }
  end

  def importprivkey( bitcoinprivkey, label='', rescan=true )
    {
      method: :importprivkey,
      params:[bitcoinprivkey, label, rescan]
    }
  end

    # ["key","key"]'> [account] Add a nrequired-to-sign multisignature address to the wallet. Each key is a bitcoin address or hex-encoded public key. If [account] is specified, assign address to [account].  N
  def addmultisigaddress( nrequired, keys, account='' )
    {
      method: :addmultisigaddress,
      params:[nrequired, keys, account]
    }
  end      

  # addnode  <node> <add/remove/onetry> version 0.8 Attempts add or remove <node> from the addnode list or try a connection to <node> once.  N
  def addnode( node, action )
    {
      method: :addnode,
      params:[node, action]
    }
  end     
# backupwallet   <destination>   Safely copies wallet.dat to destination, which can be a directory or a path with filename.  N
  def backupwallet( destination )
    {
      method: :backupwallet,
      params:[destination]
    }
  end

# createmultisig   <nrequired> <'["key,"key"]'>  Creates a multi-signature address and returns a json object  
  def createmultisig( nrequired, keys )
    {
      method: :createmultisig,
      params:[nrequired, keys]
    }
  end 

# createrawtransaction   [{"txid":txid,"vout":n},...] {address:amount,...}  version 0.7 Creates a raw transaction spending given inputs.   N
  def createrawtransaction( inputs, output_hashes )
    {
      method: :createrawtransaction,
      params:[inputs, output_hashes]
    }
  end 

# decoderawtransaction   <hex string> version 0.7 Produces a human-readable JSON object for a raw transaction.   N
  def decoderawtransaction(hexstring)
    {
      method: :decoderawtransaction,
      params:[hexstring]
    }
  end 

#   gettxout   <txid> <n> [includemempool=true]  Returns details about an unspent transaction output (UTXO)  N
  def gettxout(txid, n, includemempool=true)
    {
      method: :gettxout,
      params:[txid, n, includemempool]
    }
  end

  def gettransaction(txid)
    {
      method: :gettransaction,
      params:[txid]
    }
  end
  
# gettxoutsetinfo    Returns statistics about the unspent transaction output (UTXO) set  N
  def gettxoutsetinfo
    {
      method: :gettxoutsetinfo,
      params:[]
    }
  end

# listunspent  [minconf=1] [maxconf=999999] version 0.7 Returns array of unspent transaction inputs in the wallet.   N
  def listunspent(minconf=1, maxconf=999999)
    {
      method: :listunspent,
      params:[minconf, maxconf]
    }
  end

# listlockunspent   version 0.8 Returns list of temporarily unspendable outputs
  def listlockunspent
    {
      method: :listlockunspent,
      params:[hexstring]
    }
  end

# lockunspent  <unlock?> [array-of-objects] version 0.8 Updates list of temporarily unspendable outputs
  def lockunspent(unlock, objects)
    {
      method: :lockunspent,
      params:[unlock, objects]
    }
  end 

  def getmininginfo
    {
      method: :getmininginfo,
      params:[]
    }
  end 


end
