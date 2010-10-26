# sinatra-respond\_to

* http://www.github.com/cehoffman/sinatra-respond\_to

## DESCRIPTION:

A respond\_to style Rails block for baked-in web service support in Sinatra

## FEATURES/PROBLEMS:

* Handles setting the content type depending on what is being served
* Automatically can adjust XMLHttpRequests to return Javascript

## SYNOPSIS:

Allows urls of the form **/posts**, **/posts.rss**, and **/posts?format=atom** to route to the same Sinatra block and format specific respond\_to block.

    require 'sinatra'
    require 'sinatra/respond_to'
    
    Sinatra::Application.register Sinatra::RespondTo

    get '/posts' do
      @posts = Post.recent

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
      @comment = Comment.find(params[:id])

      respond_to do |wants|
        wants.html { haml :comment }    # => views/comment.html.haml, also sets content_type to text/html
        wants.json { @comment.to_json } # => sets content_type to application/json
        wants.js { erb :comment }       # => views/comment.js.erb, also sets content_type to application/javascript
      end
    end

To change the character set of the response, there is a `charset` helper.  For example

    get '/iso-8859-1' do
      charset 'iso-8859-1'
      "This is now sent using iso-8859-1 character set"
    end

    get '/respond_to-mixed' do
      respond_to do |wants|
        wants.html { charset 'iso-8859-1'; "Some html in iso-8859-1" }
        wants.xml { builder :utf-8-xml }    # => this is returned in the default character set
      end
    end

## CONFIGURATION:

There a few options available for configuring the default behavior of respond\_to using Sinatra's `set` utility.

* **default\_content - :html**
      When a user vists a url without an extension, for example /post this will be
      the assumed content to serve first.  Expects a symbol as used in setting content_type.
* **assume\_xhr\_is\_js - true**
      To avoid headaches with accept headers, and appending .js to urls, this will
      cause the default format for all XmlHttpRequests to be classified as wanting Javascript
      in the response.

## REQUIREMENTS:

* sinatra 1.1

If you would like to use Sinatra 1.0, use version `0.5.0`.

## INSTALL:

    $ gem install sinatra-respond_to

## CAVEATS:
Due to the way respond\_to works, all incoming requests have the extension striped from the request.path\_info. This causes routes like the following to fail.

    get '/style.css' do
      sass :style   # => renders views/style.sass
    end

They need to be changed to the following.

    get '/style' do
      sass :style   # => renders views/style.css.sass
    end

If you want to ensure the route only gets called for css requests try this.  This will use sinatra's built in accept header matching.

    get '/style', :provides => :css do
      sass :style
    end

## DEVELOPERS:

After checking out the source, run:

    $ bundle install
    $ rake spec

This task will install any missing dependencies, run the tests/specs, and generate the RDoc.

## Contributors

* [Ryan Schenk](http://github.com/rschenk/)

## LICENSE:

(The MIT License)

Copyright (c) 2009-2010 Chris Hoffman

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
