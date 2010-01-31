require 'sinatra/base'
require 'erb'
require 'haml'
require 'sass'
require 'builder'

class TestApp < Sinatra::Base
  register Sinatra::RespondTo

  set :views, File.join(File.dirname(__FILE__), 'views')
  set :public, File.join(File.dirname(__FILE__), 'public')

  get '/resource' do
    respond_to do |wants|
      wants.html { haml :resource }
      wants.json { "We got some json" }
      wants.xml { builder :resource }
      wants.js { erb :resource }
      wants.png { }
    end
  end

  get '/default_charset' do
    respond_to do |wants|
      wants.html { "Should set charcter set to default_charset" }
    end
  end

  get '/iso-8859-1' do
    respond_to do |wants|
      wants.html { charset 'iso-8859-1'; "Should have character set of iso-8859-1" }
    end
  end

  get '/normal-no-respond_to' do
    "Just some plain old text"
  end

  get '/style.css' do
    "This route should fail"
  end

  get '/style-no-extension', :provides => :css do
    "Should succeed only when browser accepts text/css"
  end

  get '/missing-template' do
    respond_to do |wants|
      wants.html { haml :missing }
      wants.xml { builder :missing }
      wants.js { erb :missing }
      wants.css { sass :missing }
    end
  end
end