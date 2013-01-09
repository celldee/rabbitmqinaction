require 'bunny'

conn = Bunny.new
conn.start

ch = conn.channel
x = conn.direct('hello-exchange', :durable => true)

msg = ARGV[0]
x.publish(msg, :routing_key => 'hola')
