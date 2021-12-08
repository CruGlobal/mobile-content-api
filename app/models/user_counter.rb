class UserCounter < ApplicationRecord
  # This decay rate yields a half life of about 90 days with the following equation:
  # f(x, t): x * e ^ (r * t)
  DECAY_RATE = -0.0077

  belongs_to :user
  has_many :user_counter_values
  validates :counter_name, format: {with: /\A[-_.a-zA-Z0-9]+\z/, message: "has invalid characters"}

  def decay
    date_now = Time.now.utc.to_date
    self.last_decay ||= date_now
    days_to_decay = date_now - last_decay

    if days_to_decay > 0
      self.decayed_count *= (Math::E**(DECAY_RATE * days_to_decay))
      self.last_decay = date_now
    end
  end

  def values
    user_counter_values.pluck(:value)
  end
end
