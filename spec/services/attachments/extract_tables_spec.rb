require "rails_helper"

RSpec.describe Attachments::ExtractTables, type: :service do
  it "extracts normalized table rows from raw extracted text" do
    attachment = create(
      :attachment,
      raw_extracted_text: <<~TEXT
        School Year 2025-2026
        Course  1  2  3  Teacher
        Language Arts  88  91  87  McDonnell, L
        Mathematics  97  92  90  Krcmar, M
      TEXT
    )

    result = described_class.call(attachment)

    expect(result["detected"]).to eq(true)
    expect(result["school_year"]).to eq("2025-2026")
    expect(result["period_columns"]).to eq(%w[q1 q2 q3])
    expect(result["row_count"]).to eq(2)
    expect(result["header"]).to include("course", "q1", "q2", "q3")
    expect(result["rows"].first["course"]).to eq("Language Arts")
    expect(result["rows"].first["period_scores"]).to eq({ "q1" => "88", "q2" => "91", "q3" => "87" })
    expect(result["rows"].first["teacher"]).to eq("McDonnell, L")
  end
end
