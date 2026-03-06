class Artifact < ApplicationRecord
  SOURCE_TYPES = %w[email upload parent_note system].freeze
  CONTENT_TYPES = %w[message image pdf document mixed unknown].freeze
  PROCESSING_STATES = %w[pending detecting extracting_text classifying processed failed].freeze
  AI_STATUSES = %w[pending processing complete failed].freeze
  TEXT_EXTRACTION_METHODS = %w[native ocr native_plus_ocr none].freeze
  SYSTEM_CATEGORIES = %w[
    school_communication
    assignment
    report_card
    assessment_result
    health_record
    health_observation
    parent_observation
    behavior_note
    social_emotional_signal
    administrative_document
    other
  ].freeze

  belongs_to :child
  has_many_attached :files

  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :content_type, inclusion: { in: CONTENT_TYPES }
  validates :processing_state, inclusion: { in: PROCESSING_STATES }
  validates :ai_status, inclusion: { in: AI_STATUSES }
  validates :text_extraction_method, inclusion: { in: TEXT_EXTRACTION_METHODS }, allow_nil: true
  validates :system_category, inclusion: { in: SYSTEM_CATEGORIES }, allow_nil: true
  validates :captured_at, presence: true

  scope :recent_first, -> {
    order(Arel.sql("occurred_at DESC NULLS LAST, captured_at DESC"))
  }

  def effective_category
    user_category.presence || system_category
  end

  def email?
    source_type == "email"
  end

  def upload?
    source_type == "upload"
  end

  def parent_note?
    source_type == "parent_note"
  end

  def message?
    content_type == "message"
  end

  def image?
    content_type == "image"
  end

  def pdf?
    content_type == "pdf"
  end

  def document?
    content_type == "document"
  end

  def categorized?
    effective_category.present?
  end

  def needs_ocr?
    image? || metadata.to_h["needs_ocr"] == true
  end

  def display_title
    return title if title.present?
    return subject if subject.present?
    return effective_category.to_s.humanize if effective_category.present?

    "Untitled Artifact"
  end
end
