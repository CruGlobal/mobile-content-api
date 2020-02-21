class AddServiceTypeToDestination < ActiveRecord::Migration[5.2]
  def change
    add_column :destinations, :service_type, :string

    Destination.reset_column_information
    Destination.update_all service_type: :growth_spaces
    Destination.create! url: 'https://mc.adobe.io/',
                        service_type: :adobe_campaigns

    change_column_null :destinations, :service_type, false
  end
end
