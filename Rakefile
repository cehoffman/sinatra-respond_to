# -*- ruby -*-

require 'rubygems'
require 'hoe'
require File.expand_path(File.join('.', 'lib', 'sinatra', 'respond_to', 'version'))

Hoe.plugin :gemcutter
Hoe.plugin :clean
Hoe.plugin :git

Hoe.spec 'sinatra-respond_to' do
  developer('Chris Hoffman', 'cehoffman@gmail.com')

  extra_deps << ['sinatra', '>= 0.9.4']
  extra_dev_deps = [
    ['rspec', '>= 1.3.0'],
    ['rcov', '>= 0.9.7.1'],
    ['rack-test', '>= 0.5.3'],
    ['haml', '>= 2.0'],
    ['builder', '>= 2.0'],
  ]

  self.readme_file = 'README.rdoc'
  self.history_file = 'Changelog.rdoc'
  self.test_globs = 'spec/*_spec.rb'
  self.version = ::Sinatra::RespondTo::Version
end

Rake.application.instance_variable_get('@tasks').delete('release')
desc "Release gem to gemcutter"
task :release => [:release_to_gemcutter]

begin
  require 'spec/rake/spectask'
  namespace :spec do
    desc "Run specs"
    Spec::Rake::SpecTask.new do |t|
      t.spec_files = FileList['spec/*_spec.rb']
      t.spec_opts = "--options spec/spec.opts"

      t.rcov = true
      t.rcov_opts << '--sort coverage --text-summary --sort-reverse'
      t.rcov_opts << "--comments --exclude pkg,#{ENV['GEM_HOME']}"
    end
  end
rescue LoadError
  puts "RSpec not available. Install it with sudo gem install rspec."
end

# vim: syntax=ruby
