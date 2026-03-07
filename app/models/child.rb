class Child < ApplicationRecord
  belongs_to :parent
  has_many :communications, dependent: :destroy
  has_many :artifacts, through: :communications
  has_many :insights, dependent: :destroy

  validates :name, presence: true
  validates :inbound_alias, uniqueness: true, allow_nil: true

  before_validation :ensure_inbound_alias, on: :create

  def regenerate_inbound_alias!
    update!(inbound_alias: generate_unique_alias)
  end

  private

  def ensure_inbound_alias
    self.inbound_alias ||= generate_unique_alias
  end

  def generate_unique_alias
    loop do
      candidate = SecureRandom.alphanumeric(10).downcase
      break candidate unless Child.exists?(inbound_alias: candidate)
    end
  end
end
