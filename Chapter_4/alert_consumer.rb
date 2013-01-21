require 'bunny'
require 'json'
require 'mail'

class AlertsConsumer < Bunny::Consumer
  
  def cancelled?
    @cancelled
  end

  def handle_cancellation(_)
    @cancelled = true
  end
end

def send_mail(recipients, title, msg)
  # Send mail via GMail
  Mail.defaults do
    delivery_method :smtp, { 
      :address => 'smtp.gmail.com',
      :port => '587',
      :user_name => '<GMail User>',
      :password => '<GMail Password>',
      :authentication => :plain,
      :enable_starttls_auto => true
    }
  end

  mail = Mail.new do
    from    '<Alert Email Address>'
    to      recipients
    subject title
    body    msg
  end

  mail.deliver!
end

conn = Bunny.new(:user => 'alert_user', :password => 'alertme')
conn.start

t1 = Thread.new do
  ch1 = conn.create_channel
  exch1 = ch1.topic("alerts")
  q_critical = ch1.queue("critical").bind(exch1, :routing_key => "critical.*")

  consumer = AlertsConsumer.new(ch1, q_critical, 'critical', false)
  
  # Pass block to consumer delivery handler
  consumer.on_delivery() do |delivery_info, metadata, payload|
    recipients = ['<Recipient1>', '<Recipient2>']
    msg = JSON.parse(payload)
    send_mail(recipients, 'CRITICAL ALERT', msg)
    
    puts ("Sent alert via e-mail! Alert Text: #{msg} Recipients: #{recipients.to_s}")

    # Acknowledge message
    ch1.ack(delivery_info.delivery_tag, false)
  end
  
  # Register the consumer
  q_critical.subscribe_with(consumer, :block => true)
end
t1.abort_on_exception = true

t2 = Thread.new do
  ch2 = conn.create_channel
  exch2 = ch2.topic("alerts")
  q_rate_limit = ch2.queue("rate_limit").bind(exch2, :routing_key => "*.rate_limit")

  consumer = AlertsConsumer.new(ch2, q_rate_limit, 'rate_limit', false)
  
  # Pass block to consumer delivery handler
  consumer.on_delivery() do |delivery_info, metadata, payload|
    recipients = ['<Recipient1>', '<Recipient2>']
    msg = JSON.parse(payload)
    send_mail(recipients, 'RATE LIMIT ALERT', msg)
    
    puts ("Sent alert via e-mail! Alert Text: #{msg} Recipients: #{recipients.to_s}")
    
    # Acknowledge message
    ch2.ack(delivery_info.delivery_tag, false)
  end
  
  # Register the consumer
  q_rate_limit.subscribe_with(consumer, :block => true)
end
t2.abort_on_exception = true

[t1, t2].each do |t|
  t.join
end

conn.close
