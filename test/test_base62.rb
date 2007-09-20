#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require 'rubygems'
require 'mosquito'
require File.dirname(__FILE__) + "/../hurl/base62"

class TestBase62 < Camping::UnitTest
  include Base62
  def test_alphabet_characters_should_only_validate
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

  def test_edge_62_to_the_0_convertions_should_be_valid
    (0...62).each do |i|
      encode = base62_encode(i)
      decode = base62_decode(encode)
      assert_equal i, decode, "interger #{i} was encoded as #{encode} and was decoded to #{decode}"
    end
  end

  def test_edge_62_to_the_n_convertions_should_be_valid
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

