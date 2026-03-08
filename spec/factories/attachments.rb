FactoryBot.define do
  factory :attachment, class: "Attachment" do
    association :communication
    child { communication.child }
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

    after(:build) do |attachment|
      next if attachment.communication.blank?
      next if attachment.child.blank?
      next if attachment.communication.child_id == attachment.child_id

      attachment.communication = build(:communication, child: attachment.child)
    end
  end
end
