## About


## Examples

    require 'sinatra'
    require 'sinatra/respond_to'
    register Sinatra::RespondTo         # => Due to bug in sinatra for classic applications and extensions, see Issues
    
    get '/posts' do
      @posts = Posts.recent
      
      respond_to do |wants|
        wants.html { haml :posts }      # => views/posts.html.haml, also sets content_type to text/html
        wants.rss { haml :posts }       # => views/posts.rss.haml, also sets content_type to application/rss+xml
        wants.atom { haml :posts }      # => views/posts.atom.haml, also sets content_type to appliation/atom+xml
      end
    end

    get '/post/:id' do
      @post = Post.find(params[:id])
      
      respond_to do |wants|
        wants.html { haml :post }       # => views/post.html.haml, also sets content_type to text/html
        wants.xhtml { haml :post }      # => views/post.xhtml.haml, also sets content_type to application/xhtml+xml
        wants.xml { @post.to_xml }      # => sets content_type to application/xml
        wants.js { erb :post }          # => views/post.js.erb, also sets content_type to application/javascript
      end
    end
    
    get '/comments/:id' do
      @comment = Comments.find(params[:id])
      
      respond_to do |wants|
        wants.html { haml :comment }    # => views/comment.html.haml, also sets content_type to text/html
        wants.json { @comment.to_json } # => sets content_type to application/json
        wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
      end
    end

## Configuration

There a few options available for configuring the default behavior of respond_to using Sinatra's
<tt>set</tt> utility.

* <tt>default\_charset - utf-8</tt><br />
    Assumes all text documents are encoded using this character set.
    This can be overridden within the respond_to block for the appropriate format
* <tt>default\_content - :html</tt><br />
    When a user vists a url without an extension, for example /post this will be
    the assumed content to serve first.  Expects a symbol as used in setting content_type.
* <tt>assume\_xhr\_is\_js - true</tt><br />
    To avoid headaches with accept headers, and appending .js to urls, this will
    cause the default format for all XmlHttpRequests to be classified as wanting Javascript
    in the response.

## Installing
Coming soon...

## Cavaets
Due to the way respond\_to works, all incoming requests have the extension striped from the request.path\_info.
This causes routes like the following to fail.

    get '/style.css' do
      sass :style   # => renders views/style.sass
    end
    
They need to be changed to the following

    get '/style' do
      sass :style   # => renders views/style.css.sass
    end
    
If you want to ensure the route only gets called for css requests try this

    get '/style', :provides => :css do
      sass :style
    end

## Issues

Sinatra has a bug that affects Classic style applications and extensions see [#215][215] and [#180][180].
For this reason you'll have explicitly register Sinatra::RespondTo for classic applications just like for
non-classic applications.

[215]: https://sinatra.lighthouseapp.com/projects/9779/tickets/215-extensions-cannot-define-before-filters-for-classic-apps "Extensions cannot define before filters for classic apps"
[180]: https://sinatra.lighthouseapp.com/projects/9779/tickets/180-better-route-inheritence "Better route inheritence"

