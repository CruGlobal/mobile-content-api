class BaseSharingChannel < ApplicationCable::Channel
  METADATA_CACHE_PREFIX = "sharing_metadata"
  METADATA_EXPIRY = 2.hours
  SUBSCRIBER_TO_PUBLISHER = "subscriber_to_publisher"

  protected

  def metadata
    @metadata ||= Rails.cache.fetch([METADATA_CACHE_PREFIX, @publisher_channel_id]) {
      {}
    }
  end

  def set_metadata(key, value)
    metadata[key] = value
    Rails.cache.write([METADATA_CACHE_PREFIX, @publisher_channel_id], metadata, expires_in: METADATA_EXPIRY)
  end

  def clear_metadata
    Rails.cache.delete([METADATA_CACHE_PREFIX, @publisher_channel_id])
  end

  def format_error(title, detail = nil)
    inner_hash = {"title" => title}
    inner_hash["detail"] = detail if detail

    {"errors": [inner_hash]}
  end

  def validate_channel_id_format(channel_id, channel_name)
    if channel_id.blank?
      transmit(format_error("#{channel_name.capitalize} Channel Missing"))
      false
    elsif /\A[a-zA-Z0-9-]{5,200}\z/.match?(channel_id)
      true
    else
      transmit(format_error("#{channel_name.capitalize} Channel Invalid"))
      false
    end
  end
end
