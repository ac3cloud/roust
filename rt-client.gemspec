# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name    = "rt-client"
  s.version = "0.5.0"

  s.authors = ["Tom Lahti"]
  s.date = %q{2013-09-05}
  s.email = %q{toml@bitstatement.net}

  s.requirements = ["A working installation of RT with the REST 1.0 interface"]
  s.summary = %q{Ruby client for RT's REST API}
  s.description = <<-DOC
    RT_Client is a ruby object that accesses the REST interface version 1.0
    of a Request Tracker instance.  See http://www.bestpractical.com/ for
    Request Tracker.
  DOC

  s.required_ruby_version     = ">= 1.8.7"
  s.required_rubygems_version = ">= 1.3.6"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'rest-client',         ">= 0.9"
  s.add_runtime_dependency 'tmail',               "= 1.2.7.1"
  s.add_runtime_dependency 'mime-types',          ">= 1.16"
  s.add_runtime_dependency 'archive-tar-minitar', ">= 0.5"
  s.add_runtime_dependency 'nokogiri',            ">= 1.2"
end
