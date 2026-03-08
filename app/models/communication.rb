class Communication < ApplicationRecord
  AI_STATUSES = %w[pending processing complete failed].freeze
  CHAT_SOURCE = "agent_chat"

  belongs_to :child
  has_many :attachments, class_name: "Attachment", dependent: :destroy, inverse_of: :communication
  has_many :communication_correspondents, class_name: "CommunicationContact", dependent: :destroy
  has_many :correspondents, through: :communication_correspondents, source: :contact

  before_validation :ensure_default_correspondent
  validates :ai_status, inclusion: { in: AI_STATUSES }
  validate :must_have_at_least_one_correspondent

  private

  def ensure_default_correspondent
    return if correspondents.any?
    return if from_email.blank?

    default = Correspondent.find_or_initialize_by(email: from_email.downcase)
    default.name = from_name.presence || from_email if default.name.blank?
    default.family ||= child.parent.family if child&.parent&.family.present?
    default.save! if default.new_record? || default.changed?
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

  def agent_chat?
    source == CHAT_SOURCE
  end

  def chat_messages
    Array(raw_payload.to_h["chat_messages"]).select { |entry| entry.is_a?(Hash) }
  end

  def append_chat_message!(role:, content:, references: nil, warning: nil, at: Time.current)
    entry = {
      "role" => role.to_s,
      "content" => content.to_s,
      "at" => at.iso8601
    }
    entry["references"] = references if references.present?
    entry["warning"] = warning if warning.present?

    updated_messages = chat_messages + [entry]
    update!(raw_payload: raw_payload.to_h.merge("chat_messages" => updated_messages))
  end

end
