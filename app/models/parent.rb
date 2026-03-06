class Parent < ApplicationRecord
  belongs_to :family
  has_many :children, dependent: :destroy
  has_many :contacts, through: :family

  validates :email, presence: true, uniqueness: true
end
