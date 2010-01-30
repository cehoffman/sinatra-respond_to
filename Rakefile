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
  extra_dev_deps << ['hoe', '>= 2.5.0']
  extra_dev_deps << ['rspec', '>= 1.3.0']
  extra_dev_deps << ['rcov', '>= 0.9.7.1']
  extra_dev_deps << ['rack-test', '>= 0.5.3']
  extra_dev_deps << ['haml', ">= 2.0"]
  extra_dev_deps << ['builder', '>= 2.0']
  self.readme_file = 'README.rdoc'
  self.history_file = 'Changelog.rdoc'
  self.test_globs = 'spec/*_spec.rb'
  self.version = ::Sinatra::RespondTo::Version
end

begin
  require 'spec/rake/spectask'
  desc "Run specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/*_spec.rb']
    t.spec_opts = %w(-fp --color)

    t.rcov = true
    t.rcov_opts << '--text-summary'
    t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
    t.rcov_opts << '--exclude' << 'pkg,spec'
  end
rescue LoadError
  puts "RSpec not available. Install it with sudo gem install rspec."
end

# vim: syntax=ruby
