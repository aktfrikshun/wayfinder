FactoryBot.define do
  factory :communication do
    association :child
    source { "postmark" }
    from_email { "teacher@example.com" }
    from_name { "Ms. Carter" }
    subject { "Weekly update" }
    received_at { Time.current }
    body_text { "Progress is steady." }
    body_html { "<p>Progress is steady.</p>" }
    raw_payload { { "Subject" => "Weekly update" } }
    ai_status { "pending" }

    transient do
      correspondents_count { 1 }
    end

    after(:create) do |communication, evaluator|
      create_list(:correspondent, evaluator.correspondents_count).each do |correspondent|
        communication.correspondents << correspondent unless communication.correspondents.include?(correspondent)
      end
    end
  end
end
