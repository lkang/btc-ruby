# bitcoind_api.rb
require 'coind_api'

class BitcoindApi < CoindApi
  if Rails.env == 'development'
    BITCOIND_SERVER_URL = 'http://localhost:18332'
  else
    BITCOIND_SERVER_URL = 'http://localhost:8332'
  end

  #/Users/you/Library/Application Support/Bitcoin/bitcoin.conf

  BITCOIND_SERVER_USERNAME = ENV['BITCOIND_SERVER_USERNAME'] || 'BITCOIND_SERVER_USERNAME'
  BITCOIND_SERVER_PASSWORD = ENV['BITCOIND_SERVER_PASSWORD'] || 'BITCOIND_SERVER_PASSWORD'

  def server_url
    BITCOIND_SERVER_URL
  end

  def auth
    { 
      username: BITCOIND_SERVER_USERNAME,
      password: BITCOIND_SERVER_PASSWORD
    }
  end

end
