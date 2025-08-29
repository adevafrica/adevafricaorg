class CreateProjectUpdates < ActiveRecord::Migration[7.0]
  def change
    create_table :project_updates do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.integer :update_type, default: 1
      t.boolean :published, default: false
      t.datetime :published_at
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :project_updates, :project_id
    add_index :project_updates, :update_type
    add_index :project_updates, :published
    add_index :project_updates, :published_at
    add_index :project_updates, :created_at
  end
end

