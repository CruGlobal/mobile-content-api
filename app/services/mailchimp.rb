# frozen_string_literal: true

class Mailchimp
  class << self
    def subscribe(user)
      return unless configured?

      merge_fields = {FNAME: user.first_name, LNAME: user.last_name}.reject { |_k, v| v.blank? }
      client.lists(list_id).members(subscriber_hash(user.email)).upsert(body: {
        email_address: user.email,
        status_if_new: "subscribed",
        merge_fields: merge_fields
      })
    end

    def remove(email, permanent: false)
      return unless configured?

      member = client.lists(list_id).members(subscriber_hash(email))
      if permanent
        member.actions.delete_permanent.create
      else
        member.delete
      end
    rescue Gibbon::MailChimpError => e
      raise unless e.status_code == 404
    end

    private

    def configured?
      ENV["MAILCHIMP_API_KEY"].present? && list_id.present?
    end

    def list_id
      ENV["MAILCHIMP_LIST_ID"]
    end

    def client
      Gibbon::Request.new(api_key: ENV["MAILCHIMP_API_KEY"])
    end

    def subscriber_hash(email)
      Digest::MD5.hexdigest(email.downcase)
    end
  end
end
