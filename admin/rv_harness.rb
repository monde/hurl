
# Example mongrel harness for camping apps with rv
#
# author: Evan Weaver
# url: http://blog.evanweaver.com/articles/2006/12/19/rv-a-tool-for-luxurious-camping
# license: AFL 3.0


# This is the Hurl example of Evan's rb_harness.rb.  Remember that hurl.rb migrates its
# database based on a ENV['CAMPING_ENV'] variable

require 'rubygems'
require 'mongrel'
require 'mongrel/camping'
LOGFILE = 'mongrel.log'
PIDFILE = 'mongrel.pid'

# or whatever else you want passed in
PORT = ARGV[0].to_i
ADDR = ARGV[1]

# this is your camping app
require 'hurl' 
app = Hurl

# custom database configuration
app::Models::Base.establish_connection :adapter => 'sqlite3',
  :database => 'db/hurl.db'

#app::Models::Base.logger = Logger.new(LOGFILE) # comment me out if you don't want to log
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

