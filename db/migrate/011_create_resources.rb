class CreateResources < ActiveRecord::Migration[7.0]
  def change
    create_table :resources do |t|
      t.string :title, null: false
      t.text :description
      t.integer :resource_type, null: false
      t.integer :access_level, default: 0
      t.boolean :published, default: false
      t.string :external_url
      t.text :content
      t.integer :download_count, default: 0
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :resources, :resource_type
    add_index :resources, :access_level
    add_index :resources, :published
    add_index :resources, :created_at
  end
end

