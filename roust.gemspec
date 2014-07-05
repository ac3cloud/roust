# -*- encoding: utf-8 -*-
$LOAD_PATH.push(File.expand_path('../lib', __FILE__))
require 'roust/version'

Gem::Specification.new do |s|
  s.name    = 'roust'
  s.version = Roust::VERSION
  s.date    = Time.now.strftime('%Y-%m-%d')

  s.authors = ['Lindsay Holmwood']
  s.email   = ['lindsay@holmwood.id.au']
  s.summary      = "Ruby client for RT's REST API"
  s.description  = "Roust is a Ruby API client to access Request Tracker's REST interface."
  s.homepage     = 'http://github.com/bulletproofnetworks/roust'
  s.license      = 'Apache 2.0'

  s.required_ruby_version     = '>= 1.9.2'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = %w(lib)

  s.add_runtime_dependency 'mail',                '>= 2.5.4'
  s.add_runtime_dependency 'httparty',            '>= 0.13.1'
  s.add_runtime_dependency 'activesupport',       '>= 4.1.0'
end
