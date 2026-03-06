class Contact < ApplicationRecord
  belongs_to :family
  belongs_to :user, optional: true

  has_many :communication_contacts, dependent: :destroy
  has_many :communications, through: :communication_contacts

  validates :email, uniqueness: { scope: :family_id, case_sensitive: false }, allow_blank: true
  validates :phone, uniqueness: { scope: :family_id }, allow_blank: true

  before_validation :normalize_email

  def display_name
    name.presence || email.presence || "Contact ##{id}"
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.presence
  end
end
