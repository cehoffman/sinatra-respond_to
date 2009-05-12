# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{sinatra-respond_to}
  s.version = "0.3.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Hoffman"]
  s.date = %q{2009-05-12}
  s.description = %q{A respond_to style Rails block for baked-in web service support in Sinatra}
  s.email = %q{cehoffman@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.markdown"
  ]
  s.files = [
    "LICENSE",
    "README.markdown",
    "Rakefile",
    "VERSION.yml",
    "lib/sinatra/respond_to.rb"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/cehoffman/sinatra-respond_to}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{A respond_to style Rails block for baked-in web service support in Sinatra}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<sinatra-sinatra>, [">= 0.9.1.3"])
    else
      s.add_dependency(%q<sinatra-sinatra>, [">= 0.9.1.3"])
    end
  else
    s.add_dependency(%q<sinatra-sinatra>, [">= 0.9.1.3"])
  end
end
