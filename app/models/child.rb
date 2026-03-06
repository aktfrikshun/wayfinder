class Child < ApplicationRecord
  belongs_to :parent
  has_many :communications, dependent: :destroy
  has_many :artifacts, through: :communications

  validates :name, presence: true
  validates :inbound_alias, uniqueness: true, allow_nil: true
end
