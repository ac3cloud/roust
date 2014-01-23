# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = "rt-client"
  s.version = "1.0.0"

  s.authors = ["Lindsay Holmwood"]
  s.date = %q{2014-01-23}
  s.email = %q{lindsay@holmwood.id.au}

  s.summary      = %q{Ruby client for RT's REST API}
  s.description  = %q{RT::Client is a ruby object that accesses the REST interface version 1.0 of a Request Tracker instance.  See http://www.bestpractical.com/ for Request Tracker.}

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
