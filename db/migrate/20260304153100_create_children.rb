class CreateChildren < ActiveRecord::Migration[8.1]
  def change
    create_table :children do |t|
      t.references :parent, null: false, foreign_key: true
      t.string :name, null: false
      t.string :grade
      t.string :school_name
      t.string :inbound_alias

      t.timestamps
    end

    add_index :children, :inbound_alias, unique: true
  end
end
