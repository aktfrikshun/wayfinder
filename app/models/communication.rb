class Communication < ApplicationRecord
  AI_STATUSES = %w[pending processing complete failed].freeze

  belongs_to :child

  validates :ai_status, inclusion: { in: AI_STATUSES }
end
