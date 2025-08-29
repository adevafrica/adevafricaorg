class CreateTeams < ActiveRecord::Migration[7.0]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.text :description
      t.string :website
      t.string :location
      t.boolean :active, default: true
      t.jsonb :social_links, default: {}
      t.text :mission_statement
      t.integer :founded_year
      
      t.timestamps
    end

    add_index :teams, :name, unique: true
    add_index :teams, :active
    add_index :teams, :location
  end
end

