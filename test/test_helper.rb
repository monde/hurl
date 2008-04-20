#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require 'rubygems'
require 'mosquito'
require 'mocha'
require File.dirname(__FILE__) + "/../hurl"

Hurl::HENV = :test

Hurl.create
