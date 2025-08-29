class CreateVotes < ActiveRecord::Migration[7.0]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.references :vote_round, null: true, foreign_key: true
      t.integer :vote_type, null: false
      t.text :comment
      t.decimal :weight, precision: 8, scale: 2, default: 1.0
      t.jsonb :metadata, default: {}
      
      t.timestamps
    end

    add_index :votes, [:user_id, :project_id], unique: true
    add_index :votes, :project_id
    add_index :votes, :vote_round_id
    add_index :votes, :vote_type
    add_index :votes, :created_at
  end
end

