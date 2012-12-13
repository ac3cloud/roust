# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rt-client}
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tom Lahti"]
  s.date = %q{2011-08-23}
  s.description = %q{    RT_Client is a ruby object that accesses the REST interface version 1.0
    of a Request Tracker instance.  See http://www.bestpractical.com/ for
    Request Tracker.
}
  s.email = %q{toml@bitstatement.net}
  s.require_paths = ["."]
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.6")
  s.requirements = ["A working installation of RT with the REST 1.0 interface"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Ruby object for RT access via REST}

  s.files = Dir['README.md', 'rt-client.gemspec', '**/*.rb']

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 0.9"])
      s.add_runtime_dependency(%q<tmail>, [">= 1.2.0"])
      s.add_runtime_dependency(%q<mime-types>, [">= 1.16"])
      s.add_runtime_dependency(%q<archive-tar-minitar>, [">= 0.5"])
      s.add_runtime_dependency(%q<nokogiri>, [">= 1.2"])
      s.add_runtime_dependency(%q<hoe>, [">= 1.9.0"])
      s.add_runtime_dependency(%q<rcov>, [">= 0.8"])
    else
      s.add_dependency(%q<rest-client>, [">= 0.9"])
      s.add_dependency(%q<tmail>, [">= 1.2.0"])
      s.add_dependency(%q<mime-types>, [">= 1.16"])
      s.add_dependency(%q<archive-tar-minitar>, [">= 0.5"])
      s.add_dependency(%q<nokogiri>, [">= 1.2"])
      s.add_dependency(%q<hoe>, [">= 1.9.0"])
      s.add_dependency(%q<rcov>, [">= 0.8"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 0.9"])
    s.add_dependency(%q<tmail>, [">= 1.2.0"])
    s.add_dependency(%q<mime-types>, [">= 1.16"])
    s.add_dependency(%q<archive-tar-minitar>, [">= 0.5"])
    s.add_dependency(%q<nokogiri>, [">= 1.2"])
    s.add_dependency(%q<hoe>, [">= 1.9.0"])
    s.add_dependency(%q<rcov>, [">= 0.8"])
  end
end
