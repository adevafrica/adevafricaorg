class CreateAssistantResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :assistant_responses do |t|
      t.references :assistant, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :project, null: true, foreign_key: true
      t.text :question, null: false
      t.text :response
      t.integer :status, default: 0
      t.datetime :completed_at
      t.jsonb :metadata, default: {}
      t.decimal :cost, precision: 8, scale: 4, default: 0
      
      t.timestamps
    end

    add_index :assistant_responses, :assistant_id
    add_index :assistant_responses, :user_id
    add_index :assistant_responses, :project_id
    add_index :assistant_responses, :status
    add_index :assistant_responses, :completed_at
    add_index :assistant_responses, :created_at
  end
end

