class SubscribeChannel < ApplicationCable::Channel
  def subscribed
    stream_from "subscribe_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
