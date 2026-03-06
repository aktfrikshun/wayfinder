class SetDefaultParentRoleForUsers < ActiveRecord::Migration[8.1]
  def up
    change_column_default :users, :role, from: nil, to: "PARENT"
    execute <<~SQL.squish
      UPDATE users
      SET role = 'PARENT'
      WHERE role IS NULL OR role = ''
    SQL
    change_column_null :users, :role, false
  end

  def down
    change_column_null :users, :role, true
    change_column_default :users, :role, from: "PARENT", to: nil
  end
end
