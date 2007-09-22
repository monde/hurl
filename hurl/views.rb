#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

module Hurl

  PATH = File.expand_path("#{File.dirname(__FILE__)}/../")

  ## 
  # we are defining our own Hurl#render rather than Hurl::Views#layout
  # so that we can support Erb rendering

  def render(m, layout=true)
    content = ERB.new(IO.read("#{PATH}/templates/#{m}.rhtml")).result(binding) rescue ''

    # assumes html layout
    if layout
      @title =  "hurl it"
      @base_url = base_url

      # if one has google analytics javascript put it in the urchin.txt file
      @urchin = IO.read("#{PATH}/templates/urchin.txt") rescue nil
      content = ERB.new(IO.read("#{PATH}/templates/layout.rhtml")).result(binding) if layout
    end
    return content
  end
end

=begin
Normally Hurl::Views and a layout would be here
=end
