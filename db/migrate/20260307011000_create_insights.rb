class CreateInsights < ActiveRecord::Migration[7.1]
  def change
    create_table :insights do |t|
      t.references :child, null: false, foreign_key: true
      # avoid default index so we can add a unique one below
      t.references :artifact, null: false, foreign_key: true, index: false
      t.string :title, null: false
      t.text :body
      t.string :priority
      t.float :confidence
      t.string :status, null: false, default: "active"
      t.jsonb :signals, default: {}

      t.timestamps
    end

    add_index :insights, :artifact_id, unique: true, name: "index_insights_on_artifact_id_unique", if_not_exists: true
    add_index :insights, :priority
    add_index :insights, :status
  end
end
