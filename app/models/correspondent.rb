class Correspondent < ApplicationRecord
  belongs_to :user, optional: true

  has_many :communication_correspondents, dependent: :destroy
  has_many :communications, through: :communication_correspondents

  validates :email, uniqueness: { case_sensitive: false }, allow_blank: true

  before_validation :normalize_email

  def display_name
    name.presence || email.presence || "Correspondent ##{id}"
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.presence
  end
end
