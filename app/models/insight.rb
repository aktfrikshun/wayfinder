class Insight < ApplicationRecord
  belongs_to :child
  belongs_to :artifact

  STATUSES = %w[active archived].freeze
  PRIORITIES = %w[low medium high].freeze

  validates :title, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }, allow_nil: true
end
