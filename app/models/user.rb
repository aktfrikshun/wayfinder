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
  has_one :correspondent, dependent: :destroy

  validates :role, presence: true, inclusion: { in: ROLES.keys.map(&:to_s) }
  after_commit :ensure_correspondent_record, on: %i[create update]

  def role_label
    ROLES.fetch(role.to_sym)
  end

  private

  def ensure_correspondent_record
    return if email.blank?

    record = correspondent || build_correspondent
    record.email = email
    record.name = email if record.name.blank?
    record.save! if record.new_record? || record.changed?
  end
end
