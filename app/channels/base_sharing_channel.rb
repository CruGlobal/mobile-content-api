class BaseSharingChannel < ApplicationCable::Channel
  protected

  def metadata
    @metadata ||= Rails.cache.fetch(["sharing_metadata", @publisher_channel_id]) do
      {}
    end
  end

  def set_metadata(key, value)
    metadata[key] = value
    puts("BaseSharingChannel#set_metadata @publisher_channel_id: #{@publisher_channel_id.inspect}, key #{key.inspect}, value #{value.inspect}")
    Rails.cache.write(["sharing_metadata", @publisher_channel_id], metadata, expires_in: 2.hours)
  end

  def clear_metadata
    Rails.cache.delete(["sharing_metadata", @publisher_channel_id])
  end
end
