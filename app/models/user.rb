class User < ApplicationRecord
  ROLES = {
    admin: "ADMIN",
    parent: "PARENT",
    child: "CHILD",
    teacher: "TEACHER"
  }.freeze

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum :role, ROLES, suffix: true
  has_one :contact, class_name: "Contact", dependent: :destroy
  alias_method :correspondent, :contact

  before_validation :assign_default_role, on: :create
  validates :role, presence: true, inclusion: { in: ROLES.keys.map(&:to_s) }
  after_commit :ensure_correspondent_record, on: %i[create update]

  def role_label
    ROLES.fetch(role.to_sym)
  end

  private

  def assign_default_role
    self.role = :parent if role.blank?
  end

  def ensure_correspondent_record
    return if email.blank?

    parent_profile = Parent.find_by(email: email)
    fallback_family = Family.find_or_create_by!(name: "User #{id || email} Family")

    record = correspondent || build_contact
    record.family ||= parent_profile&.family || fallback_family

    record.email = email
    record.name = email if record.name.blank?
    record.save! if record.new_record? || record.changed?
  end
end
