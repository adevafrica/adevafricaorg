class CreateProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :projects do |t|
      t.references :team, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.string :category, null: false
      t.decimal :funding_goal, precision: 12, scale: 2, null: false
      t.datetime :funding_deadline
      t.integer :status, default: 0
      t.boolean :featured, default: false
      t.text :impact_statement
      t.jsonb :milestones, default: []
      t.jsonb :risks, default: []
      t.string :video_url
      t.decimal :escrow_amount, precision: 12, scale: 2, default: 0
      t.datetime :escrow_released_at
      
      t.timestamps
    end

    add_index :projects, :team_id
    add_index :projects, :category
    add_index :projects, :status
    add_index :projects, :featured
    add_index :projects, :funding_deadline
    add_index :projects, :created_at
  end
end

