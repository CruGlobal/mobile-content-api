class UserCounter < ApplicationRecord
  # This decay rate yields a half life of about 90 days with the following equation:
  # f(x, t): x * e ^ (r * t)
  DECAY_RATE = -0.0077

  belongs_to :user

  def decay
    date_now = Date.today
    self.last_decay ||= Date.today
    days_to_decay = date_now - last_decay

    if days_to_decay > 0
      self.decayed_count *= (Math::E**(DECAY_RATE * days_to_decay))
      self.last_decay = date_now
    end
  end
end
