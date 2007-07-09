# -*- ruby -*-

require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'fileutils'

require 'camping'
require 'hurl'

task :default => :test

Rake::TestTask.new("test") do |t|
  FileUtils.rm_f 'db/hurl.db'
  t.pattern = 'test/test_*.rb'
  #t.warning = true
  t.verbose = true
end

desc "Hurl goes Camping"
task :hurl do
  system "camping hurl.rb"
end

# vim: syntax=Ruby
