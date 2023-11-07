class PublishTranslationJob
  include Sidekiq::Job

  sidekiq_options lock: :until_executed

  def perform(id)
    translation = Translation.find(id)
    begin
      translation.push_published_to_s3
    rescue => e
      translation.update(publishing_errors: e.to_s)
    end
  end
end
