class CreateLocationLookups < ActiveRecord::Migration[8.1]
  def change
    create_table :location_lookups do |t|
      t.string :zip, index: true
      t.string :city
      t.string :state
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6

      # Use jsonb on PostgreSQL, otherwise fall back to text so sqlite is supported
      if connection.adapter_name.downcase.include?('postgres')
        t.jsonb :data, default: {}
      else
        t.text :data
      end

      t.datetime :cached_at

      t.timestamps
    end

    add_index :location_lookups, [:city, :state]
  end
end
