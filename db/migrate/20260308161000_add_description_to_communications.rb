class AddDescriptionToCommunications < ActiveRecord::Migration[8.1]
  def change
    add_column :communications, :description, :text
  end
end
