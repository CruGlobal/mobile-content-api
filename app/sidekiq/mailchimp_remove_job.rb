class MailchimpRemoveJob
  include Sidekiq::Job

  def perform(email, permanent = false)
    Mailchimp.remove(email, permanent: permanent)
  end
end
