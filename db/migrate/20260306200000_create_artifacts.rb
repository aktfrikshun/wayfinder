class CreateArtifacts < ActiveRecord::Migration[8.1]
  def change
    create_table :artifacts do |t|
      t.references :child, null: false, foreign_key: true
      t.string :source_type, null: false
      t.string :content_type, null: false
      t.string :title
      t.string :source
      t.string :from_email
      t.string :from_name
      t.string :subject
      t.datetime :occurred_at
      t.datetime :captured_at, null: false
      t.text :body_text
      t.text :body_html
      t.jsonb :raw_payload, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}
      t.string :text_extraction_method
      t.string :processing_state, null: false, default: "pending"
      t.text :raw_extracted_text
      t.text :ocr_text
      t.text :normalized_text
      t.float :text_quality_score
      t.string :system_category
      t.string :user_category
      t.float :category_confidence
      t.jsonb :tags, null: false, default: []
      t.jsonb :extracted_payload, null: false, default: {}
      t.string :ai_status, null: false, default: "pending"
      t.jsonb :ai_raw_response, null: false, default: {}
      t.text :ai_error

      t.timestamps
    end

    add_index :artifacts, :source_type
    add_index :artifacts, :content_type
    add_index :artifacts, :processing_state
    add_index :artifacts, :ai_status
    add_index :artifacts, :system_category
    add_index :artifacts, :occurred_at
    add_index :artifacts, :captured_at
    add_index :artifacts, :tags, using: :gin
    add_index :artifacts, :extracted_payload, using: :gin
    add_index :artifacts, :metadata, using: :gin
  end
end
