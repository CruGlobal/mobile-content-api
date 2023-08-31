class PublishTranslationJob
  include Sidekiq::Job

  def perform(id)
    translation = Translation.find(id)
    begin
      translation.push_published_to_s3
      translation.update!(is_published: true)
    rescue => e
      translation.errors.add(:error, e)
    end
  end
end
