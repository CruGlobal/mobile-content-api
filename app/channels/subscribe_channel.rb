class SubscribeChannel < BaseSharingChannel
  def subscribed
    Rails.logger.info("[SubscribeChannel#subscibed] #{params.inspect}")
    @subscriber_channel_id = params["channelId"]
    return unless validate_subscriber_channel_id_format
    @publisher_channel_id = Rails.cache.fetch([SUBSCRIBER_TO_PUBLISHER, @subscriber_channel_id])

    if @publisher_channel_id
      if metadata[:last_used_at] < METADATA_EXPIRY.ago
        transmit(format_error("Old Channel"))
        return
      elsif metadata[:last_message].present?
        transmit(metadata[:last_message])
      end
    else
      transmit(format_error("Channel Not Found"))
      return
    end

    stream_for @subscriber_channel_id
  end

  def unsubscribed
  end

  protected

  def validate_subscriber_channel_id_format
    validate_channel_id_format(@subscriber_channel_id, "Subscriber")
  end
end
