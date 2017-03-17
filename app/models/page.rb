class Page < ActiveRecord::Base

  belongs_to :resource
  has_many :translation_elements

end