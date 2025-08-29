class CreateMapLocations < ActiveRecord::Migration[7.0]
  def change
    create_table :map_locations do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.decimal :latitude, precision: 10, scale: 6, null: false
      t.decimal :longitude, precision: 10, scale: 6, null: false
      t.string :address
      t.string :city
      t.string :country
      t.jsonb :geojson
      
      t.timestamps
    end

    add_index :map_locations, :project_id
    add_index :map_locations, [:latitude, :longitude]
    add_index :map_locations, :country
    add_index :map_locations, :city
  end
end

