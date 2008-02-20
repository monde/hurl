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
require 'camping/session' unless ENV['RV_ENV'] == 'production'

Camping.goes :Hurl

require 'hurl/base62'
require 'hurl/controllers'
require 'hurl/models'
require 'hurl/views'

ENV['RV_ENV'] ||= 'testing'

##
# Hurl is a camping application that makes small urls which are
# used to represent long urls

module Hurl

  VERSION = '2.0.0'

  # the server environment Hurl is running in
  HENV = ENV['RV_ENV'] == 'production' ? :production : :test

  # we are only including this so mosquito tests work
  include Camping::Session if HENV == :test

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

    Camping::Models::Base.logger = Logger.new("hurl.log") unless Hurl::HENV == :production
  end

  Hurl::Models.create_schema
  Camping::Models::Session.create_schema unless ENV['RV_ENV'] == 'production'

end
