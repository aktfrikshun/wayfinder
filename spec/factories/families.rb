FactoryBot.define do
  factory :family do
    sequence(:name) { |n| "Family #{n}" }
  end
end
