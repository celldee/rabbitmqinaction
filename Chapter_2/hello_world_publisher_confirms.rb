require 'bunny'

def confirms_callback(delivery_tag, multiple, nack)
  if nack
    puts 'Message(s) lost!'
  else
    puts 'Confirm received!'
  end
end

conn = Bunny.new
conn.start

ch = conn.create_channel

x = ch.direct('hello-exchange', :durable => true)
q = ch.queue('hello-queue', :durable => true).bind(x, :routing_key => 'hola')

msg = ARGV[0]

ch.confirm_select(method(:confirms_callback))
100.times do |i|
  x.publish("#{i}: #{msg}", :routing_key => 'hola')
end

ch.wait_for_confirms

conn.close
