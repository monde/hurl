
# Example mongrel harness for camping apps with rv2
# based on Evan Weaver's original rv implementation:
# http://blog.evanweaver.com/articles/2006/12/19/rv-a-tool-for-luxurious-camping
#
# author: Mike Mondragon
# url: http://blog.mondragon.cc/
# license: AFL 3.0

# from the command line:
# ruby rv_harness2.rb PORT ADDRESS

require 'rubygems'
require 'mongrel'
require 'mongrel/camping'
$LOAD_PATH.unshift File.dirname(__FILE__)

ENV['CAMPING_ENV'] ||= 'production'

LOGFILE = "#{File.dirname(__FILE__)}/mongrel.log"
PIDFILE = "#{File.dirname(__FILE__)}/mongrel.pid"

# or whatever else you want passed in
PORT = ARGV[0].to_i
ADDR = ARGV[1]

# this is your camping app
require 'hurl' 
app = Hurl

if ENV['CAMPING_ENV'].eql?('production')
  app::Models::Base.establish_connection :adapter => 'mysql', 
    :database => 'hurl',
    :host => 'localhost',
    :username => 'root',
    :password => ''
else
  app::Models::Base.establish_connection :adapter => 'sqlite3',
   :database => 'db/hurl.db'
end

app::Models::Base.logger = Logger.new(LOGFILE) # comment me out if you don't want to log
app::Models::Base.threaded_connections=false
app.create

config = Mongrel::Configurator.new :host => ADDR, :pid_file => PIDFILE do
  listener :port => PORT do
    uri '/', :handler => Mongrel::Camping::CampingHandler.new(app)
    # use the mongrel static server in production instead of the camping controller
    uri '/static/', :handler => Mongrel::DirHandler.new("static/")    
    uri '/favicon.ico', :handler => Mongrel::Error404Handler.new('')
    setup_signals
    run
    write_pid_file
    log "#{app} available at #{ADDR}:#{PORT}"
    join
  end
end

