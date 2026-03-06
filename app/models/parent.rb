class Parent < ApplicationRecord
  belongs_to :family
  has_many :children, dependent: :destroy
  has_many :contacts, through: :family

  before_validation :ensure_family
  validates :email, presence: true, uniqueness: true

  private

  def ensure_family
    return if family.present?

    family_name = name.present? ? "#{name.split.first} Family" : "#{email.split('@').first.humanize} Family"
    self.family = Family.find_or_create_by!(name: family_name)
  end
end
