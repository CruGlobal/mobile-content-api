class ResourceLanguage < ActiveRecord::Base
  self.table_name = "translations"

  before_save do
    raise("this model only exists as a virtual object for serialization purposes")
  end

  belongs_to :resource
  belongs_to :language
  has_many :custom_pages, ->(obj) { joins(:page).where(pages: { resource_id: obj.resource.id }) }, through: :language
  has_many :custom_tips, ->(obj) { joins(:tip).where(tips: { resource_id: obj.resource.id }) }, through: :language

  def type
    "resource-language"
  end

  def id
    "#{resource.id}_#{language.id}"
  end

  def self.test
    rl = ResourceLanguage.new
    rl.resource = Resource.find(3)
    rl.language = Language.find(12)
    puts rl.custom_pages.inspect
    rl
  end
end
