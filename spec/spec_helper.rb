#$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rack/test'

require File.join(File.dirname(__FILE__), '..', 'lib', 'sinatra', 'respond_to')
require File.join(File.dirname(__FILE__), 'app', 'test_app')
require File.join(File.dirname(__FILE__), 'app', 'production_error_app')

RSpec.configure do |config|
  def app
    @app ||= ::Rack::Builder.new do
      run ::TestApp
    end
  end

  config.include ::Rack::Test::Methods
end
