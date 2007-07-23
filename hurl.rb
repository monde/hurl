#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require 'rubygems'
begin
  require 'erubis'
  ERB = Erubis::Eruby
rescue
  require 'erb'
end
require 'builder'
require 'mime/types'
require 'camping'
require 'camping/db'
require 'camping/session'

ENV['CAMPING_ENV'] ||= 'testing'

Camping.goes :Hurl

##
# Hurl is a camping application that makes small urls which are
# used to represent long urls

module Hurl

  VERSION = '1.0.0'

  # the server environment Hurl is running in
  HENV = ENV['CAMPING_ENV'].eql?('production') ? :production : :test

  # we are only including this so mosquito tests work
  include Camping::Session if HENV == :test

  ##
  # helper to render our pages

  def render(m=nil)
    @title =  "hurl it"
    @base_url = base_url
    content = ERB.new(
      IO.read("#{File.dirname(__FILE__)}/templates/#{m}.rhtml")
      ).result(binding) if m 
    content = ERB.new(
      IO.read("#{File.dirname(__FILE__)}/templates/layout.rhtml")
      ).result(binding) unless m.eql? :xml
    return content
  end

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
end

##
# Base62 is a module for mixing in base 62 number operations.
# It encodes a base 10 number to base 62, decodes a base 62 number
# to base 10, and verifies that number is valid within the base
# 62 alphabet that it uses.  The base 62 alphabet used is
# 0-9,A-Z,a-z

module Base62

  B62_0, B62_9, B62_A, B62_Z, B62_a, B62_z = '0'[0], '9'[0],  'A'[0], 'Z'[0], 'a'[0], 'z'[0]
  B62_CHRS = ((B62_0..B62_9).collect << (B62_A..B62_Z).collect << (B62_a..B62_z).collect).flatten

  ##
  # Encode a base 10 number into its base 62 representation

  def base62_encode(val)
    return nil if val.nil? or !val.class.eql?(Fixnum) or val < 0
    return val.to_s if val == 0
    r = ""
    until val == 0
      case mod = val % 62
      when 0..9 then r << (mod + B62_0)
      when 10..35 then r << (mod - 10 + B62_A)
      when 36...62 then r << (mod - 36 + B62_a)
      end
      val = val / 62
    end
    r.reverse
  end

  ##
  # validate the base 62 number (the key) is a comprised
  # of the valid alphabet

  def base62_validate(key)
    return false if key.nil? or !key.class.eql?(String)
    key = key.strip
    return false if key.length <= 0
    (0...key.size).each do |i|
      return false unless B62_CHRS.include?(key[i])
    end
    true
  end

  ##
  #
  # Decode a base 62 number into its base 10 representation

  def base62_decode(key)
    return nil unless base62_validate(key)
    val = 0
    key = key.reverse
    (0...key.size).each do |i|
       c = key[i]
       case
       when (B62_0..B62_9).include?(c) then norm = c - B62_0
       when (B62_A..B62_Z).include?(c) then norm = c - B62_A + 10
       when (B62_a..B62_z).include?(c) then norm = c - B62_a + 36
       end
      val = val + (norm * (62 ** i))
    end
    val
  end
end


##
# Models used by the Hurl application

module Hurl::Models

  ##
  # A Key class used to pre-fetch the unique keys used by Hurl::Url
  # Hurl::Url relies on some external entity to generate new unique
  # random keys

  class Key < Base
    extend Base62
    validates_uniqueness_of :key, :on => :create
  end
    

  ##
  # A Url class represents data and operations needed to creating
  # and finding small URLs to be thrown from larger URLs.

  class Url < Base
    extend Base62
    validates_uniqueness_of :key, :on => :create

    ##
    # The maximum width of our keys

    MAX_KEY_WIDTH = 6 # 62 ** 6 == 58B

    ##
    # Takes a URL and returns a unique base62 key for the URL and
    # saves the URL and its key to the database

    def self.put(url)
       key = Key.find(:first, :order => "id ASC")
       Key.delete(key.id)
       # keep it simple and blow up in front of the user on failures
       self.create!(:key => key.key, :url => url)
       key.key
    end

    ##
    # look up the URL for the base62 key

    def self.get(key)
      # do some basic error checking
      return nil unless base62_validate(key)
      # handle production mysql on the key column
      conditions = Hurl::HENV == :production ? "\`key\` = ?" : "key = ?"
      url = self.find(:first, :conditions => [conditions, key])
      return nil if url.nil? 

      url.increment(:hits)
      url.save # don't die if we can't increment
      url.url
    end
  end

  ##
  # Camping migration to create our database

  class CreateTheTable < V 0.1
    extend Base62
    def self.up

      case Hurl::HENV
      when :production
        # coupled to MySQL MyISAM for performance
        create_table :hurl_urls, :options => 'engine=MyISAM', :force => true do |t|
          # make varchar care about case sensitivity
          t.columns << "\`key\` varchar(#{Url::MAX_KEY_WIDTH}) BINARY NOT NULL"
        end
        add_column :hurl_urls, :url,         :string, :limit => 255, :null => false
        add_column :hurl_urls, :hits,        :integer, :default => 0
        add_column :hurl_urls, :created_at,  :datetime
      else
        # sqlite3 friendly
        create_table :hurl_urls, :force => true do |t|
          t.column :key,         :string, :limit => Url::MAX_KEY_WIDTH, :null => false
          t.column :url,         :string, :limit => 255, :null => false
          t.column :hits,        :integer, :default => 0
          t.column :created_at,  :datetime
        end
      end
      add_index :hurl_urls, :key, :unique => true

      case Hurl::HENV
      when :production
        # coupled to MySQL MyISAM
        create_table :hurl_keys, :options => 'engine=MyISAM', :force => true do |t|
          # make varchar care about case sensitivity
          t.columns << "\`key\` varchar(#{Url::MAX_KEY_WIDTH}) BINARY NOT NULL"
        end
      else
        # sqlite3 friendly
        create_table :hurl_keys, :force => true do |t|
          t.column :key,         :string, :limit => Url::MAX_KEY_WIDTH, :null => false
        end
      end

      add_index :hurl_keys, :key, :unique => true

      preload_keys
    end

    def self.down
      remove_index :hurl_urls, :key
      drop_table :hurl_urls

      remove_index :hurl_keys, :key
      drop_table :hurl_keys
    end

    def self.preload_keys
      k = Key.new
      # create and randomize 64, 3844 keys
      pow = Hurl::HENV == :production ? 2 : 1
      (0...pow).each do |pow|
        lower = 62 ** pow
        upper = 62 ** (pow+1)
        a = (lower...upper).collect.sort_by { rand }
        a.each do |i|
          key = base62_encode(i)
          Key.create!(:key => key)
        end
      end
    end
  end

end


##
# Hurl content controllers, the order of their loading is used
# as a side effect of how we handle external lookups of urls

module Hurl::Controllers

  ##
  # Get the main page
  # Will return HTML if the requester accepts text/html,
  # will return application/xml otherwise only when application/xml
  # or text/xml is requested, returns text/html otherwise
  
  class Index < R '/'

    # get the default page (show)
    def get
      accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT
      # honor html first otherwise its application/xml
      case accept
      when /text\/x?html/
        render
      when /(text|application)\/xml/
        @headers['Content-Type'] = 'application/xml charset=utf8'
        @hurl = "<hurl><message>POST url=SITE to create, GET /key to show</message></hurl>"
        render :xml
      else
        render
      end
    end

    # add a url (create)
    def post
      accept = env.ACCEPT.nil? ? env.HTTP_ACCEPT : env.ACCEPT
      iurl = @input[:url] ||= ""
      iurl.strip!

      # bad input
      if iurl.length <= 0
        @headers['Content-Type'] = 'text/plain charset=utf8'
        @status = "400"
        return "400 - Invalid url parameter"
      end

      # good input
      hurl = "#{base_url}#{Url.put(iurl)}"

      case accept
      when /text\/x?html/
        @hurl = hurl
        render :result
      when /(text|application)\/xml/
        @headers['Content-Type'] = 'application/xml charset=utf8'
        b = Builder::XmlMarkup.new
        x = b.hurl {|url| url.input(iurl); url.result(hurl) }
        @hurl = x.to_s
        render :xml
      else
        @hurl = hurl
        render :result
      end
    end
  end

# when not in the RV we'll serve static content ourselves
unless File.basename($0) =~ /rv.?_harness.rb/

  ##
  # Serve static content

  class Static < R('/static/(.+)')
    PATH = File.expand_path("#{File.dirname(__FILE__)}/")

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


##
# Lets get this party started

def Hurl.create
  # when not in the RV we'll set up the DB connection ourselves
unless File.basename($0) =~ /rv.?_harness.rb/
  case Hurl::HENV
  when :production
    Camping::Models::Base.establish_connection :adapter => 'mysql',
      :database => 'hurl',
      :host => 'localhost',
      :username => 'root',
      :password => ''
  else
    Camping::Models::Base.establish_connection :adapter => 'sqlite3',
     :database => 'db/hurl.db'
  end

#  Camping::Models::Base.logger = Logger.new("hurl.log")
  Camping::Models::Base.threaded_connections = false
end

  Hurl::Models.create_schema
  Camping::Models::Session.create_schema
end
