class PublishChannel < ApplicationCable::Channel
  def subscribed
    puts("[PublishChannel#subscibed] #{params.inspect}")
    stream_for params["channelId"]
    transmit(consumerChannelId: Time.now.to_i)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    puts("[PublishChannel#data] received data: #{data}")
  end
end
