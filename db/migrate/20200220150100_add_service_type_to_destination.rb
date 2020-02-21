class AddServiceTypeToDestination < ActiveRecord::Migration[5.2]
  def up
    add_column :destinations, :service_type, :string
    add_column :destinations, :adobe_series_name, :string

    Destination.reset_column_information
    Destination.update_all service_type: :growth_spaces
    Destination.create! url: "https://mc.adobe.io/",
                        service_type: :adobe_campaigns,
                        adobe_series_name: "GodToolsWelcomeSeries"

    change_column_null :destinations, :service_type, false
  end

  def down
    Destination.where(service_type: :adobe_campaigns).destroy_all
    remove_column :destinations, :service_type
    remove_column :destinations, :adobe_series_name
  end
end
