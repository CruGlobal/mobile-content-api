class AddServiceTypeToDestination < ActiveRecord::Migration[5.2]
  def up
    add_column :destinations, :service_type, :string
    add_column :destinations, :service_name, :string

    Destination.reset_column_information
    Destination.update_all service_type: :growth_spaces

    Destination.create! url: "https://mc.adobe.io/",
      service_type: :adobe_campaigns,
      service_name: "GodTools New Growth Series"

    change_column_null :destinations, :service_type, false
  end

  def down
    Destination.where(service_type: :adobe_campaigns).destroy_all
    remove_column :destinations, :service_type
    remove_column :destinations, :service_name
  end
end
