class CreateAssistants < ActiveRecord::Migration[7.0]
  def change
    create_table :assistants do |t|
      t.string :name, null: false
      t.text :description
      t.integer :assistant_type, null: false
      t.integer :status, default: 0
      t.jsonb :settings, default: {}
      t.text :system_prompt
      t.integer :usage_count, default: 0
      t.decimal :total_cost, precision: 10, scale: 4, default: 0
      
      t.timestamps
    end

    add_index :assistants, :assistant_type
    add_index :assistants, :status
    add_index :assistants, :name
  end
end

