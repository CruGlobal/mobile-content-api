class PublishChannel < BaseSharingChannel
  def subscribed
    puts("[PublishChannel#subscribed] #{params.inspect}")
    @publisher_channel_id = params["channelId"] # may have some validation for valid channels later
    return unless validate_publisher_channel_id_format

    stream_for @publisher_channel_id

    if metadata[:created_at]
      if metadata[:created_at] < 2.hours.ago
        clear_metadata
        setup_new_pair
      end
    else
      setup_new_pair
    end

    transmit(subscriberChannelId: metadata[:subscriber_channel_id])
  end

  def unsubscribed
  end

  def receive(data)
    @publisher_channel_id = params["channelId"]
    puts("[PublishChannel#receive] received data: #{data}.  Current metadata: #{metadata.inspect}")
    set_metadata(:last_message, data)
    transmit(confirm: Time.now)

    # send message to subscriber
    SubscribeChannel.broadcast_to metadata[:subscriber_channel_id], data
  end

	protected

  def validate_publisher_channel_id_format
    if !@publisher_channel_id
      transmit(error: "publisher channel is missing")
      false
    else # add validation for format here
    end

    true
  end

  def setup_new_pair
    subscriber_channel_id = "333" # this will be properly randomized later
    set_metadata(:subscriber_channel_id, subscriber_channel_id)
    set_metadata(:created_at, Time.now)
    remember_subscriber(subscriber_channel_id)
  end

  def remember_subscriber(subscriber_channel_id)
    Rails.cache.write(["subscriber_to_publisher", subscriber_channel_id], params["channelId"])
  end
end
