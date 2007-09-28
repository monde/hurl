#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

##
# Hurl content controllers, the order of their loading is used
# as a side effect of how we handle external lookups of urls

module Hurl::Controllers

  ##
  # derives the base url for the application as seen from the network

  def base_url
    # put a premium on Apache proxy headers, add others to your liking

    if @env['HTTP_X_FORWARDED_HOST']
      "http://#{@env['HTTP_X_FORWARDED_HOST']}/"
    else
      "http:#{self.URL}"
    end
  end

  ##
  # Get the main page
  # Will return HTML if the requester accepts text/html,
  # will return application/xml otherwise only when application/xml
  # or text/xml is requested, returns text/html otherwise
  
  class Index < R '/'

    # get the default page (show)
    def get
      # special case for the javascript toolbar
      unless @input[:url].nil?
        @hurl = url_to_hurl(@input[:url])
        render :result
      else
        accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT
        # honor html first otherwise its application/xml
        case accept
        when /text\/x?html/
          render :index
        when /(text|application)\/xml/
          @headers['Content-Type'] = 'application/xml charset=utf8'
          @hurl = "<hurl><message>POST url=SITE to create, GET /key to show</message></hurl>"
          render :xml, false
        else
          render :index
        end
      end
    end

    # add a url (create)
    def post
      accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT

      # bad input
      if (@input[:url] || "").length <= 0
        @headers['Content-Type'] = 'text/plain charset=utf8'
        @status = "400"
        return "400 - Invalid url parameter"
      end

      # good input
      hurl = url_to_hurl(@input[:url])

      case accept
      when /text\/x?html/
        @hurl = hurl
        render :result
      when /(text|application)\/xml/
        @headers['Content-Type'] = 'application/xml charset=utf8'
        b = Builder::XmlMarkup.new
        x = b.hurl {|url| url.input(@input[:url]); url.result(hurl) }
        @hurl = x.to_s
        render :xml, false
      else
        @hurl = hurl
        render :result
      end
    end

    private

    ##
    # turn a url to a hurl like http://rubyforge.org/ -> http://hurl.it/foo

    def url_to_hurl(url)
      # setup the default url no matter what
      conditions = Hurl::HENV == :production ? "\`key\` = 'it'" : "key = 'it'"
      Url.create!(:key => 'it', :url => base_url) if Url.count(:conditions => conditions) == 0

      ( url =~ /^#{Regexp.escape(base_url)}/ ) ? "#{base_url}it" : "#{base_url}#{Url.put(url)}"
    end
  end

# when not in the RV we'll serve static content ourselves
unless File.basename($0) =~ /rv.?_harness.rb/

  ##
  # Serve static content

  class Static < R('/static/(.+)')
    PATH = File.expand_path("#{File.dirname(__FILE__)}/../")

    def get file
      if file.include? '..'
        @status = '403'
        return '403 - Invalid path'
      else
        type = (MIME::Types.type_for(file)[0] || '/text/plain').to_s
        @headers['Content-Type'] = type
        @headers['X-Sendfile'] = File.join PATH, 'static', file
      end
    end
  end

end

  ##
  # Recycle junk URLs ... they are often just testers by people trying out
  # the service.  This action should be protected with basic authentication,
  # etc.

  class Admin < R '/admin/(\w+)'

    def post(*args)
      accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT
      unless args[0] == 'recycle'
        @status = '412'
        return '412 - Precondition Failed'
      end

      recycled = Url.recycle(@input)
      result = "#{recycled} keys recycled"

      case accept
      when /(text|application)\/xml/
        @headers['Content-Type'] = 'application/xml charset=utf8'
        b = Builder::XmlMarkup.new
        x = b.hurl {|message| message.message(result); message.recycled(recycled) }
        @hurl = x.to_s
        render :xml, false
      else
        @headers['Content-Type'] = 'text/plain charset=utf8'
        return result
      end
    end
  end

  ##
  # Anything else is a lookup (show) in our world

  class Translate < R '/(.+)'
    def get(key)

      accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT

      hurl = Url.get(key)
      # bad input
      if hurl.nil?
        @headers['Content-Type'] = 'text/plain charset=utf8'
        @status = "400"
        return "400 - Invalid hurl request key"
      end

      case accept
      when /text\/x?html/
        redirect hurl
      when /(text|application)\/xml/
        @headers['Content-Type'] = 'application/xml charset=utf8'
        b = Builder::XmlMarkup.new
        x = b.hurl {|url| url.key("#{base_url}#{key}"); url.value(hurl) }
        @hurl = x.to_s
        render :xml
      else
        redirect hurl
      end
    end
  end

end
