class AddProfileFieldsToChildrenAndCreateVersions < ActiveRecord::Migration[8.1]
  def change
    add_column :children, :nickname, :string
    add_column :children, :birthday, :date
    add_column :children, :height, :decimal, precision: 5, scale: 2
    add_column :children, :weight, :decimal, precision: 5, scale: 2

    create_table :versions do |t|
      t.string :whodunnit
      t.datetime :created_at
      t.bigint :item_id, null: false
      t.string :item_type, null: false
      t.string :event, null: false
      t.text :object, limit: 1_073_741_823
      t.jsonb :object_changes
    end

    add_index :versions, %i[item_type item_id]
  end
end
