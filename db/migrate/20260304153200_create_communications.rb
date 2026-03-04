class CreateCommunications < ActiveRecord::Migration[8.1]
  def change
    create_table :communications do |t|
      t.references :child, null: false, foreign_key: true
      t.string :source
      t.string :from_email
      t.string :from_name
      t.string :subject
      t.datetime :received_at
      t.text :body_text
      t.text :body_html
      t.jsonb :raw_payload, null: false, default: {}
      t.string :ai_status, null: false, default: "pending"
      t.jsonb :ai_raw_response
      t.jsonb :ai_extracted
      t.text :ai_error

      t.timestamps
    end

    add_index :communications, :received_at
    add_index :communications, :ai_status
    add_index :communications, :raw_payload, using: :gin
  end
end
