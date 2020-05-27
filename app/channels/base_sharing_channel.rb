class BaseSharingChannel < ApplicationCable::Channel
  protected

  def metadata
    @metadata ||= Rails.cache.fetch(["sharing_metadata", @publisher_channel_id]) {
      {}
    }
  end

  def set_metadata(key, value)
    metadata[key] = value
    Rails.cache.write(["sharing_metadata", @publisher_channel_id], metadata, expires_in: 2.hours)
  end

  def clear_metadata
    Rails.cache.delete(["sharing_metadata", @publisher_channel_id])
  end

  def format_error(title, detail = nil)
    inner_hash = {"title" => title}
    inner_hash["detail"] = detail if detail

    {"errors": [inner_hash]}
  end
end
