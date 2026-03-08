FactoryBot.define do
  factory :child do
    association :parent
    name { "Zammy" }
    nickname { "Z" }
    birthday { Date.new(2015, 1, 15) }
    height { 50.5 }
    weight { 62.25 }
    grade { "5" }
    school_name { "Lincoln Elementary" }
    sequence(:inbound_alias) { |n| "zammy#{n}" }
  end
end
