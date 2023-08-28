class PublishTranslationJob
  include Sidekiq::Job

  def perform(id)
    translation = Translation.find(id)
    translation.push_published_to_s3
  end
end
