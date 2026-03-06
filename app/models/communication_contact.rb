class CommunicationContact < ApplicationRecord
  belongs_to :communication
  belongs_to :contact

  validates :communication_id, uniqueness: { scope: :contact_id }
end
