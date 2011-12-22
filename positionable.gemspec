# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "positionable/version"

Gem::Specification.new do |s|
  s.name        = "positionable"
  s.version     = Positionable::VERSION
  s.authors     = ["Philippe Guégan"]
  s.email       = ["philippe.guegan@gmail.com"]
  s.homepage    = ""
  s.summary     = %q(A gem for positionning your ActiveRecord models.)
  s.description = %q(This extension provides contiguous positionning capabilities to you ActiveRecord models.)

  s.rubyforge_project = "positionable"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 2.3"
  s.add_development_dependency "sqlite3-ruby"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "factory_girl"

  s.add_dependency "activerecord", "~> 3.1"
end
