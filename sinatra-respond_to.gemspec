# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sinatra/respond_to/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'sinatra-respond_to'
  s.version     = Sinatra::RespondTo::Version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Chris Hoffman']
  s.email       = ['cehoffman@gmail.com']
  s.homepage    = 'http://github.com/cehoffman/sinatra-respond_to'
  s.summary     = 'A respond_to style Rails block for baked-in web service support in Sinatra'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_runtime_dependency 'sinatra', '~> 1.1'

  s.add_development_dependency 'rspec', '~> 2.0.1'
  s.add_development_dependency 'rack-test', '~> 0.5.6'
  s.add_development_dependency 'rcov', '~> 0.9.8'
  s.add_development_dependency 'builder', '>= 2.0'
  s.add_development_dependency 'haml', '>= 2.0'
  s.add_development_dependency 'bundler', '~> 1.0.0'

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_path = 'lib'
end
