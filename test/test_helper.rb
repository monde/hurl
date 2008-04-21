#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require 'pp'
require 'rubygems'
require 'mosquito'
require 'mocha'
require File.dirname(__FILE__) + "/../hurl"

Hurl::HENV = :test

Hurl.create

def last_hurl
  url = Hurl::Models::Url.find(Hurl::Models::Url.maximum(:id))
end
