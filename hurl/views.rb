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

  def render(kind = :html)
    template = /([_,-,0-9,a-z,A-Z]+)/.match(env.PATH_INFO)[1] rescue "index"
    @content = ERB.new(IO.read("#{PATH}/templates/#{template}.#{kind}.erb")).result(binding) rescue ''

    @title =  "hurl it"
    @base_url = base_url

    # if one has google analytics javascript put it in the urchin.txt file
    @urchin = IO.read("#{PATH}/templates/urchin.txt") rescue '' if kind == :html

    ERB.new(IO.read("#{PATH}/templates/layout.#{kind}.erb")).result(binding)
  end
end

=begin
Normally Hurl::Views and a layout would be here
=end
