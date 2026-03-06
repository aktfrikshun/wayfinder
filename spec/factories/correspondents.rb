FactoryBot.define do
  factory :correspondent do
    sequence(:email) { |n| "correspondent#{n}@example.com" }
    sequence(:name) { |n| "Correspondent #{n}" }
    phone { "555-000-0000" }
  end
end
