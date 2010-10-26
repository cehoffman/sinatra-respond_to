require File.join(File.dirname(__FILE__), 'spec_helper')

describe Sinatra::RespondTo do
  def mime_type(sym)
    ::Sinatra::Base.mime_type(sym)
  end

  describe "options" do
    it "should initialize with :default_content set to :html" do
      TestApp.default_content.should == :html
    end

    it "should initialize with :assume_xhr_is_js set to true" do
      TestApp.assume_xhr_is_js == true
    end
  end

  describe "assume_xhr_is_js" do
    it "should set the content type to application/javascript for an XMLHttpRequest" do
      header 'X_REQUESTED_WITH', 'XMLHttpRequest'

      get '/resource'

      last_response['Content-Type'].should =~ %r{#{mime_type(:js)}}
    end

    it "should not set the content type to application/javascript for an XMLHttpRequest when assume_xhr_is_js is false" do
      TestApp.disable :assume_xhr_is_js
      header 'X_REQUESTED_WITH', 'XMLHttpRequest'
      get '/resource'

      last_response['Content-Type'].should_not =~ %r{#{mime_type(:js)}}

      # Put back the option, no side effects here
      TestApp.enable :assume_xhr_is_js
    end
  end

  describe "extension routing" do
    it "should use a format parameter before sniffing out the extension" do
      get "/resource?format=xml"
      last_response.body.should =~ %r{\s*<root>Some XML</root>\s*}
    end
    
    it "breaks routes expecting an extension" do
      # In test_app.rb the route is defined as get '/style.css' instead of get '/style'
      get "/style.css"

      last_response.should_not be_ok
    end

    it "should pick the default content option for routes with out an extension, and render haml templates" do
      get "/resource"

      last_response.body.should =~ %r{\s*<html>\s*<body>Hello from HTML</body>\s*</html>\s*}
    end

    it "should render for a template using builder" do
      get "/resource.xml"

      last_response.body.should =~ %r{\s*<root>Some XML</root>\s*}
    end

    it "should render for a template using erb" do
      get "/resource.js"

      last_response.body.should =~ %r{'Hiya from javascript'}
    end

    it "should return string literals in block" do
      get "/resource.json"

      last_response.body.should =~ %r{We got some json}
    end

    # This will fail if the above is failing
    it "should set the appropriate content-type for route with an extension" do
      get "/resource.xml"

      last_response['Content-Type'].should =~ %r{#{mime_type(:xml)}}
    end

    it "should honor a change in character set in block" do
      get "/iso-8859-1"

      last_response['Content-Type'].should =~ %r{charset=iso-8859-1}
    end

    it "should return not found when path does not exist" do
      get "/nonexistant-path.txt"

      last_response.status.should == 404
    end

    describe "for static files" do
      before(:all) do
        TestApp.enable :static
      end

      after(:all) do
        TestApp.disable :static
      end

      it "should allow serving static files from public directory" do
        get '/static.txt'

        last_response.body.should == "A static file"
      end

      it "should only serve files when static routing is enabled" do
        TestApp.disable :static
        get '/static.txt'

        last_response.should_not be_ok
        last_response.body.should_not == "A static file"

        TestApp.enable :static
      end

      it "should not allow serving static files from outside the public directory" do
        get '/../unreachable_static.txt'

        last_response.should_not be_ok
        last_response.body.should_not == "Unreachable static file"
      end
    end
  end

  describe "routes not using respond_to" do
    it "should set the default content type when no extension" do
      get "/normal-no-respond_to"

      last_response['Content-Type'].should =~ %r{#{mime_type(TestApp.default_content)}}
    end

    it "should set the appropriate content type when given an extension" do
      get "/normal-no-respond_to.css"

      last_response['Content-Type'].should =~ %r{#{mime_type(:css)}}
    end
  end

  describe "error pages in production" do
    before(:each) do
      @app = Rack::Builder.new { run ::ProductionErrorApp }
    end

    describe Sinatra::RespondTo::MissingTemplate do
      it "should return 404 status when looking for a missing template in production" do
        get '/missing-template'

        last_response.status.should == 404
        last_response.body.should_not =~ /Sinatra can't find/
      end
    end

    describe Sinatra::RespondTo::UnhandledFormat do
      it "should return with a 404 when an extension is not supported in production" do
        get '/missing-template.txt'

        last_response.status.should == 404
        last_response.body.should_not =~ /respond_to/
      end
    end
  end

  describe "error pages in development:" do

    it "should allow access to the /__sinatra__/*.png images" do
      get '/__sinatra__/404.png'

      last_response.should be_ok
    end

    describe Sinatra::RespondTo::MissingTemplate do
      it "should return 500 status when looking for a missing template" do
        get '/missing-template'

        last_response.status.should == 500
      end

      it "should provide a helpful generic error message for a missing template when in development" do
        get '/missing-template.css'

        last_response.body.should =~ /missing-template\.html\.haml/
        last_response.body.should =~ %r{get '/missing-template' do respond_to do |wants| wants.html \{ haml :missing-template, layout => :app \} end end}
      end

      it "should show the /__sinatra__/500.png" do
        get '/missing-template'

        last_response.body.should =~ %r{src='/__sinatra__/500.png'}
      end

      it "should provide a contextual code example for the template engine" do
        # Haml
        get '/missing-template'

        last_response.body.should =~ %r{app.html.haml}
        last_response.body.should =~ %r{missing-template.html.haml}
        last_response.body.should =~ %r{get '/missing-template' do respond_to do |wants| wants.html \{ haml :missing-template, layout => :app \} end end}

        # ERB
        get '/missing-template.js'

        last_response.body.should =~ %r{app.html.erb}
        last_response.body.should =~ %r{missing-template.html.erb}
        last_response.body.should =~ %r{get '/missing-template' do respond_to do |wants| wants.html \{ erb :missing-template, layout => :app \} end end}

        # Builder
        get '/missing-template.xml'

        last_response.body.should =~ %r{app.xml.builder}
        last_response.body.should =~ %r{missing-template.xml.builder}
        last_response.body.should =~ %r{get '/missing-template' do respond_to do |wants| wants.xml \{ builder :missing-template, layout => :app \} end end}
      end
    end

    describe Sinatra::RespondTo::UnhandledFormat do
      it "should return with a 404 when an extension is not supported" do
        get '/missing-template.txt'

        last_response.status.should == 404
      end

      it "should provide a helpful error message for an unhandled format" do
        get '/missing-template.txt'

        last_response.body.should =~ %r{get '/missing-template' do respond_to do |wants| wants.txt \{ "Hello World" \} end end}
      end

      it "should show the /__sinatra__/404.png" do
        get '/missing-template.txt'

        last_response.body.should =~ %r{src='/__sinatra__/404.png'}
      end
    end
  end

  describe "helpers:" do
    include Sinatra::Helpers
    include Sinatra::RespondTo::Helpers

    before(:each) do
      stub!(:response).and_return({'Content-Type' => 'text/html'})
    end

    describe "charset" do
      it "should set the working charset when called with a non blank string" do
        response['Content-Type'].should_not =~ /charset/

        charset 'utf-8'

        response['Content-Type'].split(';').should include("charset=utf-8")
      end

      it "should remove the charset when called with a blank string" do
        charset 'utf-8'
        charset ''

        response['Content-Type'].should_not =~ /charset/
      end

      it "should return the current charset when called with nothing" do
        charset 'utf-8'

        charset.should == 'utf-8'
      end

      it "should fail when the response does not have a Content-Type" do
        response.delete('Content-Type')

        lambda { charset }.should raise_error
      end

      it "should not modify the Content-Type when given no argument" do
        response['Content-Type'] = "text/html;charset=iso-8859-1"

        charset

        response['Content-Type'].should == "text/html;charset=iso-8859-1"
      end
    end

    describe "format" do
      before(:each) do
        stub!(:request).and_return(Sinatra::Request.new({}))
      end

      it "should set the correct mime type when given an extension" do
        format :xml

        response['Content-Type'].split(';').should include(mime_type(:xml))
      end

      it "should fail when set to an unknown extension type" do
        lambda { format :bogus }.should raise_error
      end

      it "should return the current mime type extension" do
        format :js

        format.should == :js
      end

      it "should not modify the Content-Type when given no argument" do
        response['Content-Type'] = "application/xml;charset=utf-8"

        format

        response['Content-Type'].should == "application/xml;charset=utf-8"
      end

      it "should not return nil when only content_type sets headers" do
        settings = mock('settings')
        settings.should_receive(:default_encoding).and_return('utf-8')
        stub!(:settings).and_return(settings)

        content_type :xhtml

        format.should == :xhtml
      end
    end

    describe "static_file?" do
      before(:all) do
        TestApp.enable :static
        @static_folder = "/static folder/"
        @reachable_static_file = "/static.txt"
        @unreachable_static_file = "/../unreachable_static.txt"
      end

      after(:all) do
        TestApp.disable :static
      end

      def options
        TestApp
      end

      def unescape(path)
        Rack::Utils.unescape(path)
      end

      it "should return true if the request path points to a file in the public directory" do
        static_file?(@reachable_static_file).should be_true
      end

      it "should return false when pointing to files outside of the public directory" do
        static_file?(@unreachable_static_file).should be_false
      end

      it "should return false when the path is for a folder" do
        static_file?(@static_folder).should be_false
      end
    end

    describe "respond_to" do
      before(:each) do
        stub!(:request).and_return(Sinatra::Request.new({}))
      end

      it "should fail for an unknown extension" do
        lambda do
          respond_to do |wants|
            wants.bogus
          end
        end.should raise_error
      end

      it "should call the block corresponding to the current format" do
        format :html

        respond_to do |wants|
          wants.js { "Some JS" }
          wants.html { "Some HTML" }
          wants.xml { "Some XML" }
        end.should == "Some HTML"
      end
    end
  end
end
