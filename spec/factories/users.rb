FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    password_confirmation { "Password123!" }
    role { :parent }

    trait :admin do
      role { :admin }
    end

    trait :child_role do
      role { :child }
    end

    trait :teacher do
      role { :teacher }
    end

    trait :relative do
      role { :relative }
    end
  end
end
