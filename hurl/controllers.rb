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
  # get the 

  def accept
    env.HTTP_ACCEPT.nil? ? (env.ACCEPT.nil? ? 'text/html' : env.ACCEPT) : env.HTTP_ACCEPT
  end

  def exit_with_error(status, message)
    @headers['Content-Type'] = 'text/plain; charset=utf8'
    @status = status
    "#{status} - #{message}"
  end

  ##
  # Get the main page
  # Will return HTML if the requester accepts text/html, will return 
  # application/xml otherwise when application/xml or text/xml is requested, 
  # returns text/html otherwise.

  class Index < R '/'
    def get
      if (accept =~ /(text|application)\/xml/) && (accept =~ /text\/x?html/).nil?
        @headers['Content-Type'] = 'application/xml; charset=utf8'
        render :xml
      else
        render
      end
    end
  end

  ##
  # API controller for creating Hurls

  class Api < R '/api'

    include Parkpass

    ##
    # myOpenID authentication will come back to /api as GET so just bump back
    # to root '/'

    def get
      redirect '/'
    end

    ##
    # add a url (create)

    def post

# XXX PUT POST TIMER HERE

      return exit_with_error("401", "OpenID Authenticaiton Required") unless authenticate_with_open_id

      # bad or spam input
      url = URI.parse(@input[:url]) rescue nil

      return exit_with_error("400", "Invalid url parameter") if url.nil? || url.host.nil?

      @input = url
      @hurl = url_to_hurl(url)

      if (accept =~ /(text|application)\/xml/) && (accept =~ /text\/x?html/).nil?
        @headers['Content-Type'] = 'application/xml; charset=utf8'
        render :xml, :result
      else
        render :html, :result
      end

    end

    private

    ##
    # take a URL and return a hurl address, e.g. http://hurl.it/aB4

    def url_to_hurl(url)
      hurl = base_uri

      if url.host == hurl.host
        path = '/it'
      else
        u = Url.url_to_hurl(url.to_s, env.REMOTE_ADDR)
        path = "/#{u.token}"
      end
      hurl.path = path
      hurl
    end


  end

# when not in the RV we'll serve static content ourselves
unless File.basename($0) =~ /rv.?_harness.rb/

  ##
  # Serve static content

  class Static < R('/static/(.+)')
    PATH = File.expand_path("#{File.dirname(__FILE__)}/../")

    def get file
      return exit_with_error("403", "Invalid path") if file.include? '..'

      type = (MIME::Types.type_for(file)[0] || '/text/plain').to_s
      @headers['Content-Type'] = type
      @headers['X-Sendfile'] = File.join PATH, 'static', file
    end
  end

end

  ##
  # Anything else is a token to look up the original url

  class Translate < R '/(.+)'

    def get(token)

      begin
        hurl = Url.find_by_token(token, env)
      rescue ActiveRecord::RecordNotFound => err
        # bad input
        return exit_with_error("400", "Invalid request: #{err}")
      end

      @token = token
      @hurl = hurl.url
      if (accept =~ /(text|application)\/xml/) && (accept =~ /text\/x?html/).nil?
        @headers['Content-Type'] = 'application/xml; charset=utf8'
        render :xml, (hurl.spam? ? :spam : :redirect)
      else
        if hurl.spam?
          render :html, :spam
        else
          redirect hurl.url
        end
      end
    end
  end

end
