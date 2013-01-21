require 'bunny'
require 'optparse'
require 'json'

options = {}

optparse = OptionParser.new do |opts|
  opts.on( '-r key', '--routing_key=key', "Routing key for message (e.g. myalert.im)") do |r|
    options[:routing_key] = r
  end
  
  opts.on( '-m msg', '--message=msg', "Message text for alert") do |m|
    options[:message] = m
  end
  
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

msg = JSON.generate([options[:message]])

conn = Bunny.new(:user => 'alert_user', :password => 'alertme')
conn.start

ch = conn.channel

ch.basic_publish(msg,
                 'alerts', options[:routing_key],
                 {:persistent => false, :content_type => 'application/json'}
                )

conn.close
