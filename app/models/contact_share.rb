class ContactShare < ApplicationRecord
  belongs_to :contact
  belongs_to :parent

  validates :contact_id, uniqueness: { scope: :parent_id }
end
