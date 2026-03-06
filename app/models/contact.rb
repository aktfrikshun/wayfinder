class Contact < ApplicationRecord
  belongs_to :family
  belongs_to :user, optional: true

  has_many :communication_contacts, dependent: :destroy
  has_many :communications, through: :communication_contacts

  validates :email, uniqueness: { scope: :family_id, case_sensitive: false }, allow_blank: true
  validates :phone, uniqueness: { scope: :family_id }, allow_blank: true

  before_validation :normalize_email
  before_validation :ensure_family

  def display_name
    name.presence || email.presence || "Contact ##{id}"
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.presence
  end

  def ensure_family
    return if family.present?

    family_from_parent =
      if user&.email.present?
        Parent.find_by(email: user.email)&.family
      elsif email.present?
        Parent.find_by(email: email)&.family
      end

    self.family = family_from_parent || Family.find_or_create_by!(name: "General Contacts")
  end
end
