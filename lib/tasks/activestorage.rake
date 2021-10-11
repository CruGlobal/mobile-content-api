# frozen_string_literal: true

namespace :activestorage do
  task migrate: :environment do
    Rails.logger = Logger.new($stdout)
    Attachment.where.not(file_file_name: nil).find_each do |attachment|
      # This step helps us catch any attachments we might have uploaded that
      # don't have an explicit file extension in the filename
      file = attachment.file_file_name
      ext = File.extname(file)
      file_original = CGI.unescape(file.gsub(ext, "_original#{ext}"))
      s3 = Aws::S3::Client.new(region: ENV["AWS_REGION"], access_key_id: ENV["AWS_ACCESS_KEY_ID"],
        secret_access_key: ENV["AWS_SECRET_ACCESS_KEY"])
      # this url pattern can be changed to reflect whatever service you use
      file_key = format("attachments/files/000/000/%03d/original/#{file}", attachment.id)
      begin
        File.open("tmp/#{file_original}", "wb") do |fd|
          s3.get_object(bucket: ENV["MOBILE_CONTENT_API_BUCKET"], key: file_key) do |chunk|
            fd.write(chunk)
          end
        end
        attachment.file.attach(io: open("tmp/#{file_original}"),
          filename: attachment.file_file_name,
          content_type: attachment.file_content_type)
        attachment.filename = file
        attachment.save!
      rescue => error
        Rails.logger.warn("#{error.message} #{attachment.class.name} Model => #{file}")
      end
    end
  end
end
