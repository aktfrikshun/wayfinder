class Attachment < ApplicationRecord
  attr_accessor :replace_files

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
  belongs_to :communication
  has_many_attached :files
  has_one_attached :raw_email
  has_many :insights, inverse_of: :attachment, dependent: :destroy

  validates :source_type, inclusion: { in: SOURCE_TYPES }
  validates :content_type, inclusion: { in: CONTENT_TYPES }
  validates :processing_state, inclusion: { in: PROCESSING_STATES }
  validates :ai_status, inclusion: { in: AI_STATUSES }
  validates :text_extraction_method, inclusion: { in: TEXT_EXTRACTION_METHODS }, allow_nil: true
  validates :system_category, inclusion: { in: SYSTEM_CATEGORIES }, allow_nil: true
  validates :captured_at, presence: true
  validate :communication_child_must_match

  scope :recent_first, -> {
    order(Arel.sql("occurred_at DESC NULLS LAST, captured_at DESC"))
  }

  before_validation :assign_child_from_communication

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

  def primary_file
    files.attachments.first
  end

  def file_count
    files.attachments.size
  end

  def file_names
    files.attachments.map { |att| att.filename.to_s }
  end

  def mime_types
    files.attachments.filter_map { |att| att.blob&.content_type }
  end

  def total_byte_size
    files.attachments.sum { |att| att.blob&.byte_size.to_i }
  end

  def file_metadata
    files.attachments.map do |att|
      blob = att.blob
      {
        filename: att.filename.to_s,
        content_type: blob&.content_type,
        byte_size: blob&.byte_size,
        created_at: blob&.created_at,
        checksum: blob&.checksum,
        key: blob&.key
      }
    end
  end

  def primary_file_type
    attachment = primary_file
    return nil unless attachment&.blob

    mime = attachment.blob.content_type.to_s.downcase
    ext = File.extname(attachment.filename.to_s).delete(".").downcase

    return "PDF" if mime == "application/pdf" || ext == "pdf"
    return "IMG" if mime.start_with?("image/") || %w[jpg jpeg png gif webp heic tiff bmp].include?(ext)
    return "TXT" if mime.start_with?("text/") || %w[txt md rtf].include?(ext)
    return "DOC" if mime.include?("word") || %w[doc docx odt].include?(ext)
    return "XLS" if mime.include?("sheet") || %w[xls xlsx ods csv].include?(ext)
    return "PPT" if mime.include?("presentation") || %w[ppt pptx odp].include?(ext)

    "FILE"
  end

  def primary_file_type_css
    case primary_file_type
    when "PDF" then "file-icon-pdf"
    when "IMG" then "file-icon-img"
    when "TXT" then "file-icon-txt"
    when "DOC" then "file-icon-doc"
    when "XLS" then "file-icon-xls"
    when "PPT" then "file-icon-ppt"
    else "file-icon-generic"
    end
  end

  def needs_ocr?
    image? || metadata.to_h["needs_ocr"] == true
  end

  def display_title
    return title if title.present?
    return subject if subject.present?
    return effective_category.to_s.humanize if effective_category.present?

    "Untitled Attachment"
  end

  private

  def assign_child_from_communication
    self.child_id = communication.child_id if communication.present?
  end

  def communication_child_must_match
    return if communication.blank? || child_id.blank?
    return if communication.child_id == child_id

    errors.add(:child, "must match communication child")
  end
end
