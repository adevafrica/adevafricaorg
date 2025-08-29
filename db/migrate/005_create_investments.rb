class CreateInvestments < ActiveRecord::Migration[7.0]
  def change
    create_table :investments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.integer :status, default: 0
      t.integer :payment_method, default: 0
      t.string :stripe_session_id
      t.string :stripe_payment_intent_id
      t.string :stripe_refund_id
      t.datetime :confirmed_at
      t.datetime :refunded_at
      t.text :failure_reason
      t.boolean :escrow_released, default: false
      t.datetime :escrow_released_at
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :investments, :user_id
    add_index :investments, :project_id
    add_index :investments, :status
    add_index :investments, :payment_method
    add_index :investments, :stripe_session_id
    add_index :investments, :stripe_payment_intent_id
    add_index :investments, :confirmed_at
    add_index :investments, :created_at
  end
end

