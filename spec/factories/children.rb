FactoryBot.define do
  factory :child do
    association :parent
    name { "Zammy" }
    grade { "5" }
    school_name { "Lincoln Elementary" }
    sequence(:inbound_alias) { |n| "zammy#{n}" }
  end
end
