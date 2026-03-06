class AddFamilyPhoneUniquenessToContacts < ActiveRecord::Migration[8.1]
  def change
    add_index :contacts, [:family_id, :phone],
              unique: true,
              where: "phone IS NOT NULL",
              name: "index_contacts_on_family_id_and_phone"
  end
end
