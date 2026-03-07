class CreateInsights < ActiveRecord::Migration[7.1]
  def change
    create_table :insights do |t|
      t.references :child, null: false, foreign_key: true
      t.references :artifact, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.string :priority
      t.float :confidence
      t.string :status, null: false, default: "active"
      t.jsonb :signals, default: {}

      t.timestamps
    end

    add_index :insights, [:artifact_id], unique: true
    add_index :insights, :priority
    add_index :insights, :status
  end
end
