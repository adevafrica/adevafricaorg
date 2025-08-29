class CreatePoolContributions < ActiveRecord::Migration[7.0]
  def change
    create_table :pool_contributions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pool, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :status, default: 0
      t.string :payment_reference
      t.datetime :confirmed_at
      t.datetime :refunded_at
      t.text :notes
      
      t.timestamps
    end

    add_index :pool_contributions, :user_id
    add_index :pool_contributions, :pool_id
    add_index :pool_contributions, :status
    add_index :pool_contributions, :confirmed_at
    add_index :pool_contributions, :created_at
  end
end

