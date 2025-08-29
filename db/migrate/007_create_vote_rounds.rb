class CreateVoteRounds < ActiveRecord::Migration[7.0]
  def change
    create_table :vote_rounds do |t|
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0
      t.datetime :start_date
      t.datetime :end_date
      t.jsonb :settings, default: {}
      
      t.timestamps
    end

    add_index :vote_rounds, :project_id
    add_index :vote_rounds, :status
    add_index :vote_rounds, :start_date
    add_index :vote_rounds, :end_date
  end
end

