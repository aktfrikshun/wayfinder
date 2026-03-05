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

  validates :role, presence: true, inclusion: { in: ROLES.keys.map(&:to_s) }

  def role_label
    ROLES.fetch(role.to_sym)
  end
end
