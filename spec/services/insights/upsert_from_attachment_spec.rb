require "rails_helper"

RSpec.describe Insights::UpsertFromAttachment, type: :service do
  it "builds a narrative grade trend insight from tabular quarter data" do
    child = create(:child, name: "Zammy", nickname: "Zammy")
    communication = create(:communication, child: child)
    attachment = create(
      :attachment,
      child: child,
      communication: communication,
      title: "a progress report",
      extracted_payload: {
        "tabular_data" => {
          "detected" => true,
          "school_year" => "2025-2026",
          "period_columns" => %w[q1 q2 q3],
          "rows" => [
            { "metric_label" => "Language Arts", "q1" => "88", "q2" => "91", "q3" => "94" },
            { "metric_label" => "Mathematics", "q1" => "97", "q2" => "92", "q3" => "90" }
          ]
        }
      }
    )

    insight = described_class.call(attachment)
    insight.reload

    expect(insight.title).to eq("Grade Trend Insight")
    expect(insight.body).to include("Your child Zammy just received a progress report.")
    expect(insight.body).to include("Q3 grades were generally")
    expect(insight.body).to include("School year 2025-2026.")
  end
end
