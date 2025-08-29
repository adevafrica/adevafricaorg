class CreateTeamMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :team_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :role, default: 1
      t.boolean :active, default: true
      t.datetime :joined_at
      t.datetime :left_at
      t.text :responsibilities
      
      t.timestamps
    end

    add_index :team_memberships, [:user_id, :team_id], unique: true
    add_index :team_memberships, :role
    add_index :team_memberships, :active
  end
end

