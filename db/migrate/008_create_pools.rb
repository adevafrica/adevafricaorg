class CreatePools < ActiveRecord::Migration[7.0]
  def change
    create_table :pools do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :target_amount, precision: 12, scale: 2, null: false
      t.integer :status, default: 0
      t.integer :pool_type, default: 0
      t.datetime :deadline
      t.text :terms_and_conditions
      t.jsonb :requirements, default: {}
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :pools, :status
    add_index :pools, :pool_type
    add_index :pools, :deadline
    add_index :pools, :created_at
  end
end

