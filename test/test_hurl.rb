require 'rubygems'
require 'mosquito'
require File.dirname(__FILE__) + "/../hurl"

Hurl.create
include Hurl::Models

class TestHurl < Camping::FunctionalTest

  fixtures :hurl_urls

  def test_index
    get 
    assert_response :success
    form = <<FORM
<form id="hurlform" method="post" action="/"><fieldset><label>big -&gt; </label><input type="text" class="empty" id="url" name="url" size="30"/><label> -&gt; </label><input type="submit" name="Submit" value="SUPER SMALL ME!"/></fieldset></form>
FORM
    assert_match_body %r!#{form}!
  end

  def test_xml_index
    @request.set("HTTP_ACCEPT", "application/xml")
    get 
    assert_response :success
    response = <<FORM
<hurl><message>POST url=SITE to create, GET /key to show</message></hurl>
FORM
    assert_equal response, @response.body
  end

  def test_unknown_accept_index
    @request.set("HTTP_ACCEPT", "hello/world")
    get 
    assert_response :success
    response = <<FORM
<hurl><message>POST url=SITE to create, GET /key to show</message></hurl>
FORM
    assert_equal response, @response.body
  end

  def test_post
    assert_difference(Url, :count, 1) do 
      post '', :url => 'http://sas.quat.ch/' 
    end
    assert_response :success
    results = '<h3>results</h3>'
    assert_match_body %r!#{results}!
  end

  def test_xml_post
    @request.set("HTTP_ACCEPT", "application/xml")
    assert_difference(Url, :count, 1) do 
      post '', :url => 'http://sas.quat.ch/' 
    end
    assert_response :success
    m = /\/([0-9,A-Z,a-z]+)<\/result>/m.match(@response.body)
    assert m
    assert m[1]
  end

  def test_bad_post
    assert_difference(Url, :count, 0) do 
      post '', :url => '' 
    end
    assert_response "400"
  end

  def test_bad_xml_post
    @request.set("HTTP_ACCEPT", "application/xml")
    assert_difference(Url, :count, 0) do 
      post '', :url => '' 
    end
    assert_response "400"
  end

  def test_get
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

  def test_xml_get
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

  def test_bad_get
    # bad gets are rendered not redirected
    get "/j@nkeD"
    assert_response "400"
    # there shouldn't be a a jAnkeD key
    get "/jAnkeD"
    assert_response "400"
  end

  def test_bad_xml_get
    @request.set("HTTP_ACCEPT", "application/xml")
    # bad gets are rendered not redirected
    get "/j@nkeD"
    assert_response "400"
    # there shouldn't be a a jAnkeD key
    get "/jAnkeD"
    assert_response "400"
  end
end

class TestAdd < Camping::UnitTest
  include Base62

  fixtures :hurl_urls

  def test_url_create_should_be_valid
    hurl = create()
    assert hurl.valid?
  end

private

  def create(options={})
    key = base62_encode(rand(62 ** 4))
    Url.create({ :key => key,
                 :url => "http://sas.quat.ch/"}.merge(options))
  end
    
end


class TestBase62 < Camping::UnitTest
  include Base62
  def test_alphabet_characters_only_validate
    alphabet = (('0'[0]..'9'[0]).collect << 
                ('A'[0]..'Z'[0]).collect << 
                ('a'[0]..'z'[0]).collect).flatten
    (0..255).each do |i|
      case
        when alphabet.include?(i)
           assert base62_validate(i.chr), "char #{i} is not valid as string #{i.chr}"
        else
           assert !base62_validate(i.chr), "char #{i} is valid as string #{i.chr}"
      end
    end 
  end

  def test_bad_b62_number_converstions_should_be_nil
    assert_equal nil, base62_decode(nil)
    assert_equal nil, base62_decode(8)
    assert_equal nil, base62_decode("")
    assert_equal nil, base62_decode("asfdsa!!!!!!!!!!!")
  end

  def test_edge_62_to_the_0_convertions
    (0...62).each do |i|
      encode = base62_encode(i)
      decode = base62_decode(encode)
      assert_equal i, decode, "interger #{i} was encoded as #{encode} and was decoded to #{decode}"
    end
  end

  def test_edge_62_to_the_n_convertions
    (0...3).each do |p|
      n = 62 ** p
      (0...62).each do |i|
        encode = base62_encode(i+n)
        decode = base62_decode(encode)
        assert_equal i+n, decode, "interger #{i+n} was encoded as #{encode} and was decoded to #{decode}"
      end
    end
  end
end

