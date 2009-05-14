#$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'rubygems'
require 'spec'
require 'rack/test'

require File.join(File.dirname(__FILE__), '..', 'lib', 'sinatra', 'respond_to')
require File.join(File.dirname(__FILE__), 'app', 'test_app')

Spec::Runner.configure do |config|
  def app
    @app = Rack::Builder.new do
      run TestApp
    end
  end

  config.include Rack::Test::Methods
end