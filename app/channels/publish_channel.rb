class PublishChannel < BaseSharingChannel
  def subscribed
    Rails.logger.info("[PublishChannel#subscribed] #{params.inspect}")
    @publisher_channel_id = params["channelId"] # may have some validation for valid channels later
    return unless validate_publisher_channel_id_format

    stream_for @publisher_channel_id

    if metadata[:last_used_at]
      if metadata[:last_used_at] < 2.hours.ago
        clear_metadata
        setup_new_pair
      end
    else
      setup_new_pair
    end

    transmit({data: {type: "publisher-info", attributes: {subscriberChannelId: metadata[:subscriber_channel_id]}}})
  end

  def unsubscribed
  end

  def receive(data)
    @publisher_channel_id = params["channelId"]
    Rails.logger.info("[PublishChannel#receive] received data: #{data}.  Current metadata: #{metadata.inspect}")
    set_metadata(:last_message, data)
    transmit(confirm: Time.now)

    # send message to subscriber
    data.delete("action")
    SubscribeChannel.broadcast_to metadata[:subscriber_channel_id], data
  end

  protected

  def validate_publisher_channel_id_format
    if @publisher_channel_id.blank?
      Rails.logger.info("transmit block here")
      transmit(format_error("Publisher Channel Missing"))
      false
    elsif /...../.match?(@publisher_channel_id)
      true
    else
      transmit(format_error("Publisher Channel Invalid"))
      false
    end
  end

  def setup_new_pair
    subscriber_channel_id = new_random_uid
    set_metadata(:subscriber_channel_id, subscriber_channel_id)
    set_metadata(:last_used_at, Time.now)
    remember_subscriber(subscriber_channel_id)
  end

  def remember_subscriber(subscriber_channel_id)
    Rails.cache.write(["subscriber_to_publisher", subscriber_channel_id], params["channelId"])
  end

  def new_random_uid
    "#{SecureRandom.hex(10)}_#{Time.now.to_i}"
  end
end
