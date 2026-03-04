class Parent < ApplicationRecord
  has_many :children, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
