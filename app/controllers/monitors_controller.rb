# frozen_string_literal: true
class MonitorsController < ActionController::Base
  protect_from_forgery with: :exception
  layout nil

  def lb
    ActiveRecord::Base.connection.select_values('select id from systems limit 1')
    render plain: File.read(Rails.public_path.join('lb.txt'))
  end

  def commit
    render plain: ENV['GIT_COMMIT']
  end
end
