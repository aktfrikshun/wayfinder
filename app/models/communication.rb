class Communication < ApplicationRecord
  AI_STATUSES = %w[pending processing complete failed].freeze

  belongs_to :child
  has_many :artifacts, dependent: :destroy
  has_many :communication_correspondents, class_name: "CommunicationContact", dependent: :destroy
  has_many :correspondents, through: :communication_correspondents, source: :contact

  before_validation :ensure_default_correspondent
  validates :ai_status, inclusion: { in: AI_STATUSES }
  validate :must_have_at_least_one_correspondent

  private

  def ensure_default_correspondent
    return if correspondents.any?
    return if from_email.blank?

    default = Correspondent.find_or_create_by(email: from_email.downcase) do |record|
      record.name = from_name.presence || from_email
    end
    correspondents << default
  end

  def must_have_at_least_one_correspondent
    return if correspondents.any?

    errors.add(:correspondents, "must include at least one")
  end

  public

  def display_title
    subject.presence || "Communication ##{id || 'new'}"
  end
end
