#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require File.join(File.dirname(__FILE__), 'test_helper')

include Hurl::Models

module TestHelper
end

class TestUrl < Camping::UnitTest
  include TestHelper

  def setup
    Hurl::Models::Url.delete_all
    Hurl::Models::Visit.delete_all
    @env = stub(:REMOTE_ADDR => '127.0.0.10', :HTTP_REFERER => 'http://example.com/',
                :HTTP_USER_AGENT => 'foo agent')
  end

  def test_validity
    assert_raises(ActiveRecord::RecordInvalid) do
      Hurl::Models::Url.create!
    end
    u = Hurl::Models::Url.new
    assert_equal false, u.valid?
    u = Hurl::Models::Url.new :url => 'http://example.com/'
    assert_equal true, u.valid?
  end

  def test_token
    k = rand(1024)
    u = Hurl::Models::Url.create :key => k, :url => 'http://example.com/'
    assert_equal k.alphadecimal, u.token
  end

  def test_find_by_token_increments_hits
    u = Hurl::Models::Url.create :url => 'http://example.com/'
    u = Hurl::Models::Url.find(:first, :conditions => {:key => u.key})
    count = u.hits
    assert_difference(Hurl::Models::Visit, :count, 1) do 
      u = Hurl::Models::Url.find_by_token(u.token, @env)
      assert_equal (count + 1), u.hits
    end
  end

  def test_2783_it_key_cannot_be_destroyed
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      u = Hurl::Models::Url.create(:key => 'it'.alphadecimal, :url => 'http://example.com/')
      Hurl::Models::Url.destroy(u)
    end
  end

  def test_add_visit
    u = Hurl::Models::Url.create :url => 'http://example.com/'
    assert_difference(Hurl::Models::Visit, :count, 1) do 
      u.add_visit(@env)
    end
  end

  def test_url_to_hurl
    assert_difference(Hurl::Models::Url, :count, 1) do 
      u = Hurl::Models::Url.url_to_hurl('http://example.com/', '127.0.0.10')
      assert_equal u.url, 'http://example.com/'
      assert_equal u.remote_addr, '127.0.0.10'
    end
  end
end
