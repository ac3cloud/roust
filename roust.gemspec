# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "roust/version"

Gem::Specification.new do |s|
  s.name    = "roust"
  s.version = Roust::VERSION
  s.date    = %q{2014-01-23}

  s.authors = [ "Lindsay Holmwood" ]
  s.email   = [ "lindsay@bulletproof.net" ]
  s.summary      = %q{Ruby client for RT's REST API}
  s.description  = %q{Roust is a Ruby API client that accesses the REST interface version 1.0 of a Request Tracker instance. See http://www.bestpractical.com/ for Request Tracker.}
  s.homepage     = "http://github.com/bulletproofnetworks/roust"
  s.license      = "Apache 2.0"

  s.required_ruby_version     = ">= 1.9.2"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rest-client',         ">= 0.9"
  s.add_runtime_dependency 'mail',                ">= 2.5.4"
  s.add_runtime_dependency 'mime-types',          ">= 1.16"
  s.add_runtime_dependency 'archive-tar-minitar', ">= 0.5"
  s.add_runtime_dependency 'nokogiri',            ">= 1.2"
end
