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

    TEXT_MIME_TYPES = [:txt, :html, :js, :json, :xml, :rss, :atom, :css, :asm, :c, :cc, :conf,
                       :csv, :cxx, :diff, :dtd, :f, :f77, :f90, :for, :gemspec, :h, :hh, :htm,
                       :log, :mathml, :mml, :p, :pas, :pl, :pm, :py, :rake, :rb, :rdf, :rtf, :ru,
                       :s, :sgm, :sgml, :sh, :svg, :svgz, :text, :wsdl, :xhtml, :xsl, :xslt, :yaml,
                       :yml, :ics]

    def self.registered(app)
      app.helpers RespondTo::Helpers

      app.set :default_charset, 'utf-8'
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
        unless options.static? && options.public? && (request.get? || request.head?) && static_file?(request.path_info)
          request.path_info.sub! %r{\.([^\./]+)$}, ''

          format request.xhr? && options.assume_xhr_is_js? ? :js : $1 || options.default_content

          charset options.default_charset if Sinatra::RespondTo::TEXT_MIME_TYPES.include? format
        end
      end

     app.configure :development do |dev|
        # Very, very, very hackish but only for development at least
        # Modifies the regex matching /__sinatra__/:image.png to not have the extension
        ["GET", "HEAD"].each do |verb|
          dev.routes[verb][1][0] = Regexp.new(dev.routes[verb][1][0].source.gsub(/\\\.[^\.\/]+\$$/, '$'))
        end

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
                   when 'builder' then "builder do |xml|\n  xml << yield\nend"
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
        private
          def render_with_format(*args)
            args[1] = "#{args[1]}.#{format}".to_sym if args[1].is_a?(::Symbol)
            render_without_format *args
          rescue Errno::ENOENT
            raise MissingTemplate, "#{args[1]}.#{args[0]}"
          end
          alias_method :render_without_format, :render
          alias_method :render, :render_with_format

          def lookup_layout_with_format(*args)
            args[1] = "#{args[1]}.#{format}".to_sym if args[1].is_a?(::Symbol)
            lookup_layout_without_format *args
          end
          alias_method :lookup_layout_without_format, :lookup_layout
          alias_method :lookup_layout, :lookup_layout_with_format
      end
    end

    module Helpers
      def format(val=nil)
        unless val.nil?
          mime_type = media_type(val)
          fail "Unknown media type #{val}\nTry registering the extension with a mime type" if mime_type.nil?

          @format = val.to_sym
          response['Content-Type'].sub!(/^[^;]+/, mime_type)
        end

        @format
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
          Sinatra::Base.send(:fail, "Unknown media type for respond_to: #{type}\nTry registering the extension with a mime type") if Sinatra::Base.media_type(type).nil?
          self[type] = handler
        end

        yield wants

        raise UnhandledFormat  if wants[format].nil?
        wants[format].call
      end
    end
  end

  # Get around before filter problem for classic applications by registering
  # with the context they are run in explicitly instead of Sinatra::Default
  Sinatra::Application.register RespondTo
end
