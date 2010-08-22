require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'
  namespace :spec do
    desc 'Run specs'
    RSpec::Core::RakeTask.new do |t|
      t.rcov = true
      t.rcov_opts = ['--sort coverage --text-summary --sort-reverse']
      t.rcov_opts << "--comments --exclude spec,pkg,#{ENV['GEM_HOME']}"
    end
  end
rescue LoadError
  puts 'RSpec not available, try a bundle install'
end
