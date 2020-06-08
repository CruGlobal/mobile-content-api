class PublishChannel < BaseSharingChannel
  def subscribed
    Rails.logger.info("[PublishChannel#subscribed] #{params.inspect}")
    @publisher_channel_id = params["channelId"] # may have some validation for valid channels later
    return unless validate_publisher_channel_id_format

    stream_for @publisher_channel_id

    if metadata[:last_used_at]
      if metadata[:last_used_at] < METADATA_EXPIRY.ago
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
    data.delete("action") # not needed and will break validation
    return unless validate_publisher_channel_id_format && validate_receive_message_format(data)

    set_metadata(:last_message, data)
    transmit({data: {type: "confirm-#{data.dig("data", "type")}", id: data.dig("data", "id"), attributes: (data.dig("data", "attributes") || {})}})

    # send message to subscriber
    SubscribeChannel.broadcast_to metadata[:subscriber_channel_id], data
  end

  protected

  def validate_publisher_channel_id_format
    validate_channel_id_format(@publisher_channel_id, "Publisher")
  end

  def setup_new_pair
    subscriber_channel_id = new_random_uid
    set_metadata(:subscriber_channel_id, subscriber_channel_id)
    set_metadata(:last_used_at, Time.now)
    remember_subscriber(subscriber_channel_id)
  end

  def remember_subscriber(subscriber_channel_id)
    Rails.cache.write([SUBSCRIBER_TO_PUBLISHER, subscriber_channel_id], @publisher_channel_id)
  end

  def new_random_uid
    "#{SecureRandom.hex(10)}-#{Time.now.to_i}"
  end

  # validate message is of form
  #
  # {
  #   data: {
  #     type: "navigation-event"
  #     attributes: {}
  #     id: "12345"
  #   }
  # }
  #
  # but id can be omitted
  #
  def validate_receive_message_format(data)
    valid = data.keys == ["data"] &&
      data["data"].key?("type") &&
      data["data"].key?("attributes") &&
      (data["data"].keys - %w[type attributes id]).empty? &&
      data["data"]["type"] == "navigation-event"

    unless valid
      transmit(format_error("Data format is invalid"))
    end

    valid
  end
end
