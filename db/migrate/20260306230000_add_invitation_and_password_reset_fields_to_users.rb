class AddInvitationAndPasswordResetFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :must_change_password, :boolean, null: false, default: false
    add_column :users, :temporary_password_sent_at, :datetime
    add_reference :users, :invited_by, foreign_key: { to_table: :users }
  end
end
