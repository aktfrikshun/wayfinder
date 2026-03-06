FactoryBot.define do
  factory :parent do
    association :family
    sequence(:email) { |n| "parent#{n}@example.com" }
    name { Faker::Name.name }
  end
end
