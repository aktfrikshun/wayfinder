class CreateParents < ActiveRecord::Migration[8.1]
  def change
    create_table :parents do |t|
      t.string :email, null: false
      t.string :name

      t.timestamps
    end

    add_index :parents, :email, unique: true
  end
end
