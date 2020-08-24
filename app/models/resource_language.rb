class ResourceLanguage < ActiveRecord::Base
  self.table_name = "translations"

  before_save do
    raise("this model only exists as a virtual object for serialization purposes")
  end

  belongs_to :resource
  belongs_to :language
  has_many :custom_pages, ->(obj) { joins(:page).where(pages: {resource_id: obj.resource.id}) }, through: :language
  has_many :custom_tips, ->(obj) { joins(:tip).where(tips: {resource_id: obj.resource.id}) }, through: :language
  has_one :custom_manifest, through: :resource, source: :custom_manifests
  has_many :language_attributes, ->(obj) { where(resource: obj.resource) }, through: :language

  def set_data_attributes!(data_attrs)
    data_attrs.each_pair do |key, value|
      attr_name = key[/^attr-(.*)$/, 1]
      next unless attr_name
      attr_name.tr!("-", "_")
      attribute = language.language_attributes.where(key: attr_name, resource: resource).first_or_initialize
      if value.nil?
        attribute.destroy unless attribute.new_record?
      else
        attribute.value = value.to_s
        attribute.save!
      end
    end
  end
end
