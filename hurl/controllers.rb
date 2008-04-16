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
  # derives the base uri for the application as seen from the network

  def base_uri
    URI.parse(base_url)
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
        uri = URI.parse(@input[:url]) rescue base_uri
        @hurl = url_to_hurl(uri)
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

      # bad or spam input
      uri = URI.parse(@input[:url]) rescue nil
      if uri.nil? || uri.host.nil? || is_spam?(uri)
        @headers['Content-Type'] = 'text/plain charset=utf8'
        @status = "400"
        return "400 - Invalid url parameter"
      end

      # good input
      hurl = url_to_hurl(uri)

      case accept
      when /text\/x?html/
        @hurl = hurl
        render :result
      when /(text|application)\/xml/
        @headers['Content-Type'] = 'application/xml charset=utf8'
        b = Builder::XmlMarkup.new
        x = b.hurl {|url| url.input(uri); url.result(hurl) }
        @hurl = x.to_s
        render :xml, false
      else
        @hurl = hurl
        render :result
      end
    end

    private

    ##
    # turn a url to a hurl uri like http://rubyforge.org/ -> http://hurl.it/foo

    def url_to_hurl(uri)
      # setup the default url no matter what
      Url.create!(:key => 'it', :url => base_uri.to_s) if Url.count(:id) == 0

      hurl = base_uri
      path = uri.host == hurl.host ? '/it' : "/#{Url.put(uri.to_s)}"
      hurl.path = path
      hurl
    end

    ##
    # use url and ip rbls to look for spammy uri

    def is_spam?(uri)
      if /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ =~ uri.host
        rbls = [ 'opm.blitzed.us', 'bsb.empty.us' ]
        spam = query_rbls(rbls, uri.host.split('.').reverse.join('.'))
      else
        host_parts = uri.host.split('.').reverse
        domain = Array.new
        ([ 'co', 'com', 'net', 'org', 'gov' ].include?(host_parts[1]) ? 3:2).times do
          domain.unshift(host_parts.shift)
        end
        rbls = [ 'multi.surbl.org', 'bsb.empty.us' ]
        spam = query_rbls(rbls, uri.host, domain.join('.'))
      end
      spam
    end

    ##
    # query rbls, based on Typo code

    def query_rbls(rbls, *subdomains)
      rbls.each do |rbl|
        subdomains.uniq.each do |d|
          begin
            response = IPSocket.getaddress([d, rbl].join('.'))
            # rbls return 127.0.0 if the address is spammy
            return true if response =~ /^127\.0\.0\./
          rescue SocketError
            # NXDOMAIN response => negative:  d is not in RBL
          end
        end
      end
      return false
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

  class Admin < R '/recycle'

    def post()
      accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT

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
