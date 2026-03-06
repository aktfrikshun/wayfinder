class PostmarkEvent < ApplicationRecord
  validates :event_type, presence: true

  before_validation :normalize_message_id

  private

  def normalize_message_id
    self.message_id = message_id.to_s.presence
  end
end
