require 'sinatra/base'

# Accept header parsing was looked at but deemed
# too much of an irregularity to deal with.  Problems with the header
# differences from IE, Firefox, Safari, and every other UA causes
# problems with the expected output.  The general expected behavior
# would be serve html when no extension provided, but most UAs say
# they will accept application/xml with out a quality indicator, meaning
# you'd get the xml block served insead.  Just plain retarded, use the
# extension and you'll never be suprised.

module Sinatra
  module RespondTo
    class UnhandledFormat < Sinatra::NotFound; end
    class MissingTemplate < Sinatra::NotFound
      def code; 500 end
    end

    def self.registered(app)
      app.helpers RespondTo::Helpers

      app.set :default_content, :html
      app.set :assume_xhr_is_js, true

      # We remove the trailing extension so routes
      # don't have to be of the style
      #
      #   get '/resouce.:format'
      #
      # They can instead be of the style
      #
      #   get '/resource'
      #
      # and the format will automatically be available in <tt>format</tt>
      app.before do
        # Let through sinatra image urls in development
        next if self.class.development? && request.path_info =~ %r{/__sinatra__/.*?.png}

        unless options.static? && options.public? && (request.get? || request.head?) && static_file?(request.path_info)
          if request.params.has_key? 'format'
            format params['format']
          else
            request.path_info.sub! %r{\.([^\./]+)$}, ''

            format request.xhr? && options.assume_xhr_is_js? ? :js : $1 || options.default_content
          end
        end
      end

     app.configure :development do |dev|
        dev.error UnhandledFormat do
          content_type :html, :charset => 'utf-8'

          (<<-HTML).gsub(/^ {10}/, '')
          <!DOCTYPE html>
          <html>
          <head>
            <style type="text/css">
            body { text-align:center;font-family:helvetica,arial;font-size:22px;
              color:#888;margin:20px}
            #c {margin:0 auto;width:500px;text-align:left}
            </style>
          </head>
          <body>
            <h2>Sinatra doesn't know this ditty.</h2>
            <img src='/__sinatra__/404.png'>
            <div id="c">
              Try this:
              <pre>#{request.request_method.downcase} '#{request.path_info}' do\n  respond_to do |wants|\n    wants.#{format} { "Hello World" }\n  end\nend</pre>
            </div>
          </body>
          </html>
          HTML
        end

        dev.error MissingTemplate do
          content_type :html, :charset => 'utf-8'
          response.status = request.env['sinatra.error'].code

          engine = request.env['sinatra.error'].message.split('.').last
          engine = 'haml' unless ['haml', 'builder', 'erb'].include? engine

          path = File.basename(request.path_info)
          path = "root" if path.nil? || path.empty?

          format = engine == 'builder' ? 'xml' : 'html'

          layout = case engine
                   when 'haml' then "!!!\n%html\n  %body= yield"
                   when 'erb' then "<html>\n  <body>\n    <%= yield %>\n  </body>\n</html>"
                   when 'builder' then "xml << yield"
                   end

          layout = "<small>app.#{format}.#{engine}</small>\n<pre>#{escape_html(layout)}</pre>"

          (<<-HTML).gsub(/^ {10}/, '')
          <!DOCTYPE html>
          <html>
          <head>
            <style type="text/css">
            body { text-align:center;font-family:helvetica,arial;font-size:22px;
              color:#888;margin:20px}
            #c {margin:0 auto;width:500px;text-align:left;}
            small {float:right;clear:both;}
            pre {clear:both;}
            </style>
          </head>
          <body>
            <h2>Sinatra can't find #{request.env['sinatra.error'].message}</h2>
            <img src='/__sinatra__/500.png'>
            <div id="c">
              Try this:<br />
              #{layout}
              <small>#{path}.#{format}.#{engine}</small>
              <pre>Hello World!</pre>
              <small>application.rb</small>
              <pre>#{request.request_method.downcase} '#{request.path_info}' do\n  respond_to do |wants|\n    wants.#{engine == 'builder' ? 'xml' : 'html'} { #{engine} :#{path}#{",\n#{' '*32}layout => :app" if layout} }\n  end\nend</pre>
            </div>
          </body>
          </html>
          HTML
        end

      end

      app.class_eval do
        # Changes in 1.0 Sinatra reuse render for layout so we store the
        # original value to tell us if this is an automatic attempt to do a
        # layout call.  If it is, it might fail with Errno::ENOENT and we want
        # to pass that back to sinatra since it isn't a MissingTemplate error
        alias :render_without_format :render
        def render(*args, &block)
          assumed_layout = args[1] == :layout
          args[1] = "#{args[1]}.#{format}".to_sym if args[1].is_a?(::Symbol)
          render_without_format *args, &block
        rescue Errno::ENOENT => e
          raise MissingTemplate, "#{args[1]}.#{args[0]}" unless assumed_layout
          raise e
        end
        private :render
      end
    end

    module Helpers
      # Patch the content_type function to remember the set type
      # This helps cut down on time in the format helper so it
      # doesn't have to do a reverse lookup on the header
      def self.included(klass)
        klass.class_eval do
          alias :content_type_without_save :content_type
          def content_type(*args)
            @_format = args.first.to_sym
            content_type_without_save *args
          end
        end
      end

      def format(val=nil)
        unless val.nil?
          mime_type = ::Sinatra::Base.mime_type(val)
          fail "Unknown media type #{val}\nTry registering the extension with a mime type" if mime_type.nil?

          @_format = val.to_sym
          response['Content-Type'] ? response['Content-Type'].sub!(/^[^;]+/, mime_type) : content_type(@_format)
        end

        @_format
      end

      # This is mostly just a helper so request.path_info isn't changed when
      # serving files from the public directory
      def static_file?(path)
        public_dir = File.expand_path(options.public)
        path = File.expand_path(File.join(public_dir, unescape(path)))

        path[0, public_dir.length] == public_dir && File.file?(path)
      end

      def charset(val=nil)
        fail "Content-Type must be set in order to specify a charset" if response['Content-Type'].nil?

        if response['Content-Type'] =~ /charset=[^;]+/
          response['Content-Type'].sub!(/charset=[^;]+/, (val == '' && '') || "charset=#{val}")
        else
          response['Content-Type'] += ";charset=#{val}"
        end unless val.nil?

        response['Content-Type'][/charset=([^;]+)/, 1]
      end

      def respond_to(&block)
        wants = {}
        def wants.method_missing(type, *args, &handler)
          ::Sinatra::Base.send(:fail, "Unknown media type for respond_to: #{type}\nTry registering the extension with a mime type") if ::Sinatra::Base.mime_type(type).nil?
          self[type] = handler
        end

        yield wants

        raise UnhandledFormat  if wants[format].nil?
        wants[format].call
      end
    end
  end
end
