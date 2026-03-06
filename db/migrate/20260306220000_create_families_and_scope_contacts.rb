class CreateFamiliesAndScopeContacts < ActiveRecord::Migration[8.1]
  class MigrationParent < ApplicationRecord
    self.table_name = "parents"
  end

  class MigrationContact < ApplicationRecord
    self.table_name = "contacts"
  end

  class MigrationCommunicationContact < ApplicationRecord
    self.table_name = "communication_contacts"
  end

  def up
    rename_correspondent_tables_if_needed!

    create_table :families do |t|
      t.string :name
      t.timestamps
    end

    add_reference :parents, :family, foreign_key: true
    add_reference :contacts, :family, foreign_key: true

    backfill_family_membership!

    change_column_null :parents, :family_id, false
    change_column_null :contacts, :family_id, false

    if column_exists?(:contacts, :owner_parent_id)
      remove_foreign_key :contacts, column: :owner_parent_id
      remove_column :contacts, :owner_parent_id
    end

    drop_table :contact_shares if table_exists?(:contact_shares)

    add_index :contacts, [:family_id, :email], unique: true, name: "index_contacts_on_family_id_and_email"
    add_index :communication_contacts, [:communication_id, :contact_id], unique: true, name: "idx_comm_contact_unique"
  end

  def down
    remove_index :communication_contacts, name: "idx_comm_contact_unique" if index_exists?(:communication_contacts, [:communication_id, :contact_id], name: "idx_comm_contact_unique")
    remove_index :contacts, name: "index_contacts_on_family_id_and_email" if index_exists?(:contacts, [:family_id, :email], name: "index_contacts_on_family_id_and_email")
    remove_reference :contacts, :family, foreign_key: true
    remove_reference :parents, :family, foreign_key: true
    drop_table :families
  end

  private

  def rename_correspondent_tables_if_needed!
    if table_exists?(:correspondents) && !table_exists?(:contacts)
      rename_table :correspondents, :contacts
    end

    if table_exists?(:communication_correspondents) && !table_exists?(:communication_contacts)
      rename_table :communication_correspondents, :communication_contacts
    end

    if table_exists?(:communication_contacts) && column_exists?(:communication_contacts, :correspondent_id)
      remove_index :communication_contacts, name: "idx_comm_corr_unique" if index_exists?(:communication_contacts, name: "idx_comm_corr_unique")
      rename_column :communication_contacts, :correspondent_id, :contact_id
    end
  end

  def backfill_family_membership!
    MigrationParent.find_each do |parent|
      family_name = parent.name.present? ? "#{parent.name.split.first} Family" : "Family #{parent.id}"
      family_id = execute(<<~SQL.squish).first["id"]
        INSERT INTO families (name, created_at, updated_at)
        VALUES (#{quote(family_name)}, NOW(), NOW())
        RETURNING id
      SQL
      parent.update_columns(family_id: family_id)
    end

    MigrationContact.find_each do |contact|
      family_id =
        if contact.respond_to?(:user_id) && contact.user_id.present?
          execute("SELECT family_id FROM parents WHERE email = #{quote(user_email(contact.user_id))} LIMIT 1").first&.fetch("family_id", nil)
        end

      family_id ||= execute("SELECT family_id FROM parents ORDER BY id ASC LIMIT 1").first&.fetch("family_id", nil)
      next if family_id.blank?

      contact.update_columns(family_id: family_id)
    end
  end

  def user_email(user_id)
    execute("SELECT email FROM users WHERE id = #{quote(user_id)} LIMIT 1").first&.fetch("email", nil)
  end
end
