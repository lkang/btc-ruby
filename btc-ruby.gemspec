# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'btc/version'

Gem::Specification.new do |spec|
  spec.name          = "btc-ruby"
  spec.version       = Btc::VERSION
  spec.authors       = ["lkang"]
  spec.email         = ["lkang@sbcglobal.net"]
  spec.description   = %q{Basic bitcoin utility gem}
  spec.summary       = %q{Utilities written in Ruby for manipulating bitcoin HD wallets and transactions}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "ffi"
  # spec.add_runtime_dependency "openssl"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end
