#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require 'rubygems'
require 'mosquito'
require File.dirname(__FILE__) + "/../hurl"
require File.dirname(__FILE__) + "/../hurl/base62"
require File.dirname(__FILE__) + "/../hurl/models"

Hurl.create
include Hurl::Models

module TestHelper
  include Base62

  def create_url(options={})
    key = base62_encode(rand(62 ** 4))
    Url.create({ :key => key,
                 :url => "http://sas.quat.ch/"}.merge(options))
  end
end

class TestUrl < Camping::UnitTest
  include TestHelper

  def test_recycle_should_clean_out_junk_urls
    count = Url.count
    keys = Key.count

    # one or less hits and url was created more than a month ago should be recycled
    url = create_url()
    url.created_at = 31.days.ago
    url.hits = 1
    url.save
    assert_equal keys, Key.count
    assert_equal count + 1, Url.count
    Url.recycle
    assert_equal keys + 1, Key.count
    assert_equal count, Url.count

    url = create_url()
    url.created_at = 29.days.ago
    url.hits = 0
    url.save
    assert_equal count + 1, Url.count
    Url.recycle
    assert_equal keys + 1, Key.count
    assert_equal count + 1, Url.count
  end
end

class TestAdd < Camping::UnitTest
  include Base62
  include TestHelper

  fixtures :hurl_urls

  def test_url_create_should_be_valid
    hurl = create_url()
    assert hurl.valid?
  end
 
end

