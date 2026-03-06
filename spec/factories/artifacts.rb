FactoryBot.define do
  factory :artifact do
    association :child
    source_type { "email" }
    content_type { "message" }
    title { "Weekly update" }
    source { "postmark" }
    from_email { "teacher@example.com" }
    from_name { "Ms. Carter" }
    subject { "Weekly update" }
    occurred_at { Time.current }
    captured_at { Time.current }
    body_text { "Progress is steady." }
    body_html { "<p>Progress is steady.</p>" }
    raw_payload { { "Subject" => "Weekly update" } }
    processing_state { "pending" }
    ai_status { "pending" }
    tags { [] }
    extracted_payload { {} }
    metadata { {} }
  end
end
