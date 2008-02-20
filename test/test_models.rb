#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

require File.join(File.dirname(__FILE__), 'test_helper')

include Base62
include Hurl::Models

module TestHelper
end

class TestUrl < Camping::UnitTest
  include TestHelper

  def test_false
    assert false
  end
end
