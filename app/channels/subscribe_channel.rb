class SubscribeChannel < BaseSharingChannel
  def subscribed
    puts("[SubscribeChannel#subscibed] #{params.inspect}")
    subscriber_channel_id = params["channelId"]

    unless subscriber_channel_id.present?
      reject_unauthorized_connection
      return
    end

    # TODO: validate if subscriber_channel_id is long enough/the right format

    @publisher_channel_id = Rails.cache.fetch(["subscriber_to_publisher", subscriber_channel_id])
    puts(@publisher_channel_id.inspect)
    puts("current metadata for this channel: #{metadata.inspect}")

    if @publisher_channel_id
      if metadata[:last_used_at] < 2.hours.ago
        transmit(error: "old channel")
        return
      else
        transmit(metadata[:last_message])
      end
    else
      transmit(error: "channel not found")
      return
    end

    stream_for subscriber_channel_id
  end

  def unsubscribed
  end
end
