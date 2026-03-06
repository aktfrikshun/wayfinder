class CreatePostmarkEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :postmark_events do |t|
      t.string :event_type, null: false
      t.string :message_id
      t.string :recipient
      t.datetime :recorded_at
      t.jsonb :payload, null: false, default: {}

      t.timestamps
    end

    add_index :postmark_events, :event_type
    add_index :postmark_events, :message_id
    add_index :postmark_events, :recorded_at
  end
end
