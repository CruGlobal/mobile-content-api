class ResourceLanguage < ActiveRecord::Base
  self.table_name = "translations"

  before_save do
    raise("this model only exists as a virtual object for serialization purposes")
  end

  belongs_to :resource
  belongs_to :language
  has_many :custom_pages, ->(obj) { joins(:page).where(pages: {resource_id: obj.resource.id}) }, through: :language
  has_many :custom_tips, ->(obj) { joins(:tip).where(tips: {resource_id: obj.resource.id}) }, through: :language
  has_many :language_attributes, ->(obj) { where(resource: obj.resource) }, through: :language

  def set_data_attributes!(data_attrs)
    data_attrs.each_pair do |key, value|
      attr_name = key.scan(/^attr-(.*)$/).first&.first
      next unless attr_name
      attr_name.tr!("-", "_")
      attribute = language.language_attributes.where(key: attr_name, resource: resource).first_or_initialize
      if value
        attribute.value = value
        attribute.save!
      elsif !attribute.new_record?
        attribute.destroy
      end
    end
  end
end
