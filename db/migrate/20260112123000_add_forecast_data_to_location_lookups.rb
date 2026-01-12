class AddForecastDataToLocationLookups < ActiveRecord::Migration[8.1]
  def change
    add_column :location_lookups, :forecast_data, :text
  end
end
