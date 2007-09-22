#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

##
# Base62 is a module for mixing in base 62 number operations.
# It encodes a base 10 number to base 62, decodes a base 62 number
# to base 10, and verifies that number is valid within the base
# 62 alphabet that it uses.  The base 62 alphabet used is
# 0-9,A-Z,a-z

module Base62

  B62_0, B62_9, B62_A, B62_Z, B62_a, B62_z = '0'[0], '9'[0],  'A'[0], 'Z'[0], 'a'[0], 'z'[0]
  B62_CHRS = ((B62_0..B62_9).collect << (B62_A..B62_Z).collect << (B62_a..B62_z).collect).flatten

  ##
  # Encode a base 10 number into its base 62 representation

  def base62_encode(val)
    return nil if val.nil? or !val.class.eql?(Fixnum) or val < 0
    return val.to_s if val == 0
    r = ""
    until val == 0
      case mod = val % 62
      when 0..9 then r << (mod + B62_0)
      when 10..35 then r << (mod - 10 + B62_A)
      when 36...62 then r << (mod - 36 + B62_a)
      end
      val = val / 62
    end
    r.reverse
  end

  ##
  # validate the base 62 number (the key) is a comprised
  # of the valid alphabet

  def base62_validate(key)
    return false if key.nil? or !key.class.eql?(String)
    key = key.strip
    return false if key.length <= 0
    (0...key.size).each do |i|
      return false unless B62_CHRS.include?(key[i])
    end
    true
  end

  ##
  #
  # Decode a base 62 number into its base 10 representation

  def base62_decode(key)
    return nil unless base62_validate(key)
    val = 0
    key = key.reverse
    (0...key.size).each do |i|
       c = key[i]
       case
       when (B62_0..B62_9).include?(c) then norm = c - B62_0
       when (B62_A..B62_Z).include?(c) then norm = c - B62_A + 10
       when (B62_a..B62_z).include?(c) then norm = c - B62_a + 36
       end
      val = val + (norm * (62 ** i))
    end
    val
  end
end

