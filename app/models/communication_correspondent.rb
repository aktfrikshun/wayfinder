class CommunicationCorrespondent < ApplicationRecord
  belongs_to :communication
  belongs_to :correspondent

  validates :communication_id, uniqueness: { scope: :correspondent_id }
end
