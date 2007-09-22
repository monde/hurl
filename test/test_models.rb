#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require File.dirname(__FILE__) + '/test_helper'

include Base62
include Hurl::Models

module TestHelper

  def create_url(options={})
    key = Key.find(:first, :order => "id ASC")
    Key.destroy(key.id)
    Url.create({ :key => key.key,
                 :url => "http://sas.quat.ch/"}.merge(options))
  end
end

class TestUrl < Camping::UnitTest
  include TestHelper

  def test_recycle_should_recycle_urls_with_conditions
    count = Url.count
    keys = Key.count

    bad_url = "http://www.example.com/bad"
    url = create_url(:url => bad_url)
    min_key_id = Key.minimum(:id)

    assert_equal keys - 1, Key.count
    assert_equal count + 1, Url.count
    Url.recycle(:conditions => ['url LIKE ?', "#{bad_url}%"]) # default with no args
    assert_equal keys, Key.count
    assert_equal count, Url.count
    # the recycled key has to go to the of front (minimum) keys id
    assert_equal Key.minimum(:id), min_key_id - 1
  end

  def test_recycle_should_clean_out_junk_and_dangling_urls_with_defaults
    count = Url.count
    keys = Key.count

    url = create_url()
    days_ago = 30
    hits = 0

    # the created key will be within the threshold to recycle
    url.created_at = Time.now.ago((days_ago + 1).days)
    url.hits = hits
    url.save
    min_key_id = Key.minimum(:id)

    assert_equal keys - 1, Key.count
    assert_equal count + 1, Url.count
    Url.recycle() # default with no args
    assert_equal keys, Key.count
    assert_equal count, Url.count
    # the recycled key has to go to the of front (minimum) keys id
    assert_equal Key.minimum(:id), min_key_id - 1
  end

  def test_recycle_should_clean_out_junk_and_dangling_urls
    count = Url.count
    keys = Key.count

    url = create_url()
    days_ago = 10
    hits = 5

    # the created key will be within the threshold to recycle
    url.created_at = Time.now.ago((days_ago + 1).days)
    url.hits = hits
    url.save
    min_key_id = Key.minimum(:id)

    assert_equal keys - 1, Key.count
    assert_equal count + 1, Url.count
    Url.recycle(:days_ago => days_ago, :hits => hits)
    assert_equal keys, Key.count
    assert_equal count, Url.count
    # the recycled key has to go to the of front (minimum) keys id
    assert_equal Key.minimum(:id), min_key_id - 1

    # the created key will not meet the criteria to recycle
    url = create_url()
    min_key_id = Key.minimum(:id)

    assert_equal keys - 1, Key.count
    assert_equal count + 1, Url.count
    Url.recycle(:days_ago => days_ago - 1, :hits => hits - 1)
    assert_equal keys - 1, Key.count
    assert_equal count + 1, Url.count
    assert_equal Key.minimum(:id), min_key_id
  end

  def test_recycle_should_clean_out_urls_by_id
    count = Url.count
    keys = Key.count
    url = create_url()
    min_key_id = Key.minimum(:id)

    assert_equal keys - 1 , Key.count
    assert_equal count + 1, Url.count
    Url.recycle(:id => url.id)
    assert_equal keys, Key.count
    assert_equal count, Url.count
    # the recycled key has to go to the of front (minimum) keys id
    assert_equal Key.minimum(:id), min_key_id - 1
  end
end

class TestAdd < Camping::UnitTest
  include TestHelper

  fixtures :hurl_urls

  def test_url_create_should_be_valid
    hurl = create_url()
    assert hurl.valid?
  end
 
end

