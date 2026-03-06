FactoryBot.define do
  factory :contact do
    association :family
    sequence(:email) { |n| "contact#{n}@example.com" }
    sequence(:name) { |n| "Contact #{n}" }
    phone { "555-000-0000" }
  end
end
