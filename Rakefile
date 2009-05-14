begin
  require 'jeweler'
  Jeweler::Tasks.new do |spec|
    spec.name = 'sinatra-respond_to'
    spec.summary = 'A respond_to style Rails block for baked-in web service support in Sinatra'
    spec.email = 'cehoffman@gmail.com'
    spec.homepage = 'http://github.com/cehoffman/sinatra-respond_to'
    spec.description = spec.summary
    spec.authors = ["Chris Hoffman"]
    spec.add_dependency('sinatra-sinatra', '>= 0.9.1.3')
  end
rescue LoadError
  puts "Jewler not available.  Install it with sugo gem install technicalpickles-jeweler -s http://gems.github.com"
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
    t.rcov_opts << '--exclude' << '.gem,pkg,spec'
  end
rescue LoadError
  puts "RSpec not available. Install it with sudo gem install rspec."
end