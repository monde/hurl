#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require File.dirname(__FILE__) + '/test_helper'

include Base62
include Hurl::Models
include Hurl::Controllers

class TestHurl < Camping::FunctionalTest

  def test_default_index_should_have_form
    get 
    assert_response :success
    form = <<FORM
<form id="hurlform" method="post" action="/"><fieldset><label>big -&gt; </label><input type="text" class="empty" id="url" name="url" size="30"/><label> -&gt; </label><input type="submit" name="Submit" value="SUPER SMALL ME!"/></fieldset></form>
FORM
    assert_match_body %r!#{form}!
  end

  def test_accept_xml_should_get_xml
    @request.set("HTTP_ACCEPT", "application/xml")
    get 
    assert_response :success
    response = <<FORM
<hurl><message>POST url=SITE to create, GET /key to show</message></hurl>
FORM
    assert_equal response, @response.body
  end

  def test_should_respond_with_test_html_when_accept_not_known
    @request.set("HTTP_ACCEPT", "hello/world")
    get 
    assert_response :success
    form = <<FORM
<form id="hurlform" method="post" action="/"><fieldset><label>big -&gt; </label><input type="text" class="empty" id="url" name="url" size="30"/><label> -&gt; </label><input type="submit" name="Submit" value="SUPER SMALL ME!"/></fieldset></form>
FORM
     # Hurl should respon
     assert_equal "text/html", @response.headers["Content-Type"]
     assert_match_body %r!#{Regexp.escape(form)}!
  end

  def test_post_should_have_results
    assert_difference(Url, :count, 1) do 
      post '', :url => 'http://sas.quat.ch/' 
    end
    assert_response :success
    results = '<h3>results</h3>'
    assert_match_body %r!#{results}!
  end

  def test_xml_post_should_respond_with_xml
    @request.set("HTTP_ACCEPT", "application/xml")
    assert_difference(Url, :count, 1) do 
      post '', :url => 'http://sas.quat.ch/' 
    end
    assert_response :success
    m = /\/([0-9,A-Z,a-z]+)<\/result>/m.match(@response.body)
    assert m
    assert m[1]
  end

  def test_bad_html_input_should_400
    assert_difference(Hurl::Models::Url, :count, 0) do 
      post '', :url => '' 
    end
    assert_response "400"
  end

  def test_bad_xml_input_should_400
    @request.set("HTTP_ACCEPT", "application/xml")
    assert_difference(Url, :count, 0) do 
      post '', :url => '' 
    end
    assert_response "400"
  end

  def test_hurled_url_should_be_the_same_unhurled
    # set up a real post
    to_hurl = "http://sas.quat.ch/"
    post '', :url => to_hurl
    assert_response :success
    m = /\/([0-9,A-Z,a-z]+)<\/h4>/m.match(@response.body)

    # now get it back
    assert m
    hurled = m[1]
    get "/#{hurled}"
    assert_response :redirect
    assert_equal @response.headers['Location'].to_s, to_hurl
  end

  def test_xml_request_should_get_xml
    @request.set("HTTP_ACCEPT", "application/xml")
    to_hurl = "http://sas.quat.ch/"
    post '', :url => to_hurl
    assert_response :success
    m = /\/([0-9,A-Z,a-z]+)<\/result>/m.match(@response.body)

    #now get it back
    assert m
    hurled = m[1]
    @request.set("HTTP_ACCEPT", "application/xml")
    get "/#{hurled}"
    assert_response :success
    m = /<value>http:\/\/sas.quat.ch\/<\/value>/m.match(@response.body)
    assert m
  end

  def test_bad_request_should_400
    # bad gets are rendered not redirected
    get "/j@nkeD"
    assert_response "400"
    # there shouldn't be a a jAnkeD key
    get "/jAnkeD"
    assert_response "400"
  end

  def test_bad_xml_request_should_400
    @request.set("HTTP_ACCEPT", "application/xml")
    # bad gets are rendered not redirected
    get "/j@nkeD"
    assert_response "400"
    # there shouldn't be a a jAnkeD key
    get "/jAnkeD"
    assert_response "400"
  end

  def test_recycle_should_give_some_stats
    post '/recycle'
    assert_response :success
    assert_match_body /\d+ keys recycled/
  end

  def test_urchin_included
    get "/"
    assert_response :success
    assert_match_body /put Google Analytics urchin code in templates\/urchin.txt/
  end

end