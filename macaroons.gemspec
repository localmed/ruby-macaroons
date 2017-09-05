# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'macaroons/version'

Gem::Specification.new do |spec|
  spec.name = 'macaroons'
  spec.version = Macaroons::VERSION
  spec.authors       = ["Evan Cordell", "Peter Browne", "Joel James"]
  spec.email         = ["ecordell@localmed.com", "pete@localmed.com", "joel.james@localmed.com"]
  spec.summary       = "Macaroons library in Ruby"
  spec.description   = "Macaroons library in Ruby"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  spec.required_ruby_version = "~> 2.0"
  spec.add_dependency "multi_json", "~> 1.10"
  spec.add_dependency "rbnacl", "~> 5.0"
  spec.add_dependency "rbnacl-libsodium", "~> 1.0"

  spec.add_development_dependency "bundler", "> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec",   "~> 3.1.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "rspec_junit_formatter"
end
