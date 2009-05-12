# Simple note, accept header parsing was looked at but deamed
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

      app.set :default_charset, 'utf-8' unless app.respond_to?(:default_charset)
      app.set :default_content, :html unless app.respond_to?(:default_content)
      app.set :assume_xhr_is_js, true unless app.respond_to?(:assume_xhr_is_js)

      # We remove the trailing extension so routes
      # don't have to be of the style
      #
      #   get '/resouce.:format'
      #
      # They can instead be of the style
      #
      #   get '/resource'
      #
      # and the format will automatically be available in as <tt>format</tt>
      app.before do
        unless options.static? && options.public? && ["GET", "HEAD"].include?(request.request_method) && static_file?(unescape(request.path_info))
          request.path_info.gsub! %r{\.([^\./]+)$}, ''
          format $1 || options.default_content

          # For the oh so common case of actually wanting Javascript from an XmlHttpRequest
          format :js if request.xhr? && options.assume_xhr_is_js?

          content_type format
        end
      end

      # Replace all routes that have an ending extension with one that doesn't
      # Most generally a fix for the __sinatra__ routes in development
      # app.routes.each_pair do |verb, subroutes|
      #   subroutes.each do |subroute|
      #     subroute[0] = Regexp.new(subroute[0].source.gsub(/\\\.[^\.\/]+\$$/, '$'))
      #   end
      # end

     app.configure :development do
        # Very, very, very hackish but only for development at least
        # Modifies the regex matching /__sinatra__/:image.png to not have the extension
        ["GET", "HEAD"].each do |verb|
          app.routes[verb][1][0] = Regexp.new(app.routes[verb][1][0].source.gsub(/\\\.[^\.\/]+\$$/, '$'))
        end

        app.error UnhandledFormat do
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

        app.error MissingTemplate do
          content_type :html, :charset => 'utf-8'

          engine = request.env['sinatra.error'].message[/\.([^\.]+)$/, 1]
          path = request.path_info[/([^\/]+)$/, 1]
          path = "root" if path.nil? || path.empty?

          layout = case engine
                   when 'haml' then "!!!\n%html\n  %body= yield"
                   when 'erb' then "<html>\n  <body>\n    <%= yield %>\n  </body>\n</html>"
                   when 'builder' then "builder do |xml|\n  xml << yield\nend"
                   end

          layout = "<small>app.html.#{engine}</small>\n<pre>#{escape_html(layout)}</pre>" if layout

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
              #{layout if layout}
              <small>#{path}.html.#{engine}</small>
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
            args[1] = "#{args[1]}.#{format}".to_sym
            render_without_format *args
          rescue Errno::ENOENT
            raise MissingTemplate, "#{args[1]}.#{args[0]}"
          end
          alias_method :render_without_format, :render
          alias_method :render, :render_with_format

          def lookup_layout_with_format(*args)
            args[1] = "#{args[1]}.#{format}".to_sym if args
            lookup_layout_without_format *args
          end
          alias_method :lookup_layout_without_format, :lookup_layout
          alias_method :lookup_layout, :lookup_layout_with_format
      end
    end

    module Helpers
      def format(val=nil)
        request.env['sinatra.respond_to.format'] = val.to_sym unless val.nil?
        request.env['sinatra.respond_to.format']
      end

      def static_file?(path)
        return false unless path =~ /.*[^\/]$/
        public_dir = File.expand_path(options.public)
        path = File.expand_path(File.join(public_dir, unescape(request.path_info)))
        return false if path[0, public_dir.length] != public_dir
        return false unless File.file?(path)
        true
      end

      def respond_to(&block)
        wants = {}
        def wants.method_missing(type, *args, &block)
          Sinatra::Base.send(:fail, "Unknown media type for respond_to: #{type}\nTry registering the extension with a mime type") if Sinatra::Base.media_type(type).nil?
          self[type] = block
        end

        yield wants

        handler = wants[format]
        raise UnhandledFormat  if handler.nil?

        content_type format, :charset => options.default_charset if TEXT_MIME_TYPES.include? format && response['Content-Type'] !~ /charset=/

        handler.call
      end
    end
  end

  Sinatra::Application.register RespondTo
end