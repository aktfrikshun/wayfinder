class Family < ApplicationRecord
  has_many :parents, dependent: :restrict_with_exception
  has_many :contacts, dependent: :destroy

  validates :name, presence: true
end
