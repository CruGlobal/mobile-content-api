class MailchimpSubscribeJob
  include Sidekiq::Job

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user

    Mailchimp.subscribe(user)
  end
end
