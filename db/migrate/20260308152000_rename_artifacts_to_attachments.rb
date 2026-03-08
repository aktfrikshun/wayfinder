class RenameArtifactsToAttachments < ActiveRecord::Migration[8.1]
  def up
    rename_table :artifacts, :attachments

    rename_indexes(:attachments, from_prefix: "artifacts", to_prefix: "attachments")

    if foreign_key_exists?(:insights, :artifacts, column: :artifact_id)
      remove_foreign_key :insights, column: :artifact_id
    end

    if column_exists?(:insights, :artifact_id)
      rename_column :insights, :artifact_id, :attachment_id
    end

    if index_exists?(:insights, :attachment_id, name: "index_insights_on_artifact_id_unique")
      rename_index :insights, "index_insights_on_artifact_id_unique", "index_insights_on_attachment_id_unique"
    end

    add_foreign_key :insights, :attachments, column: :attachment_id unless foreign_key_exists?(:insights, :attachments, column: :attachment_id)

    execute <<~SQL.squish
      UPDATE active_storage_attachments
      SET record_type = 'Attachment'
      WHERE record_type = 'Artifact'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE active_storage_attachments
      SET record_type = 'Artifact'
      WHERE record_type = 'Attachment'
    SQL

    remove_foreign_key :insights, column: :attachment_id if foreign_key_exists?(:insights, :attachments, column: :attachment_id)

    if column_exists?(:insights, :attachment_id)
      rename_column :insights, :attachment_id, :artifact_id
    end

    if index_exists?(:insights, :artifact_id, name: "index_insights_on_attachment_id_unique")
      rename_index :insights, "index_insights_on_attachment_id_unique", "index_insights_on_artifact_id_unique"
    end

    add_foreign_key :insights, :artifacts, column: :artifact_id unless foreign_key_exists?(:insights, :artifacts, column: :artifact_id)

    rename_table :attachments, :artifacts

    rename_indexes(:artifacts, from_prefix: "attachments", to_prefix: "artifacts")
  end

  private

  def rename_indexes(table_name, from_prefix:, to_prefix:)
    suffixes = %w[
      ai_status
      captured_at
      child_id
      communication_id
      content_type
      extracted_payload
      metadata
      occurred_at
      processing_state
      source_type
      system_category
      tags
    ]

    suffixes.each do |suffix|
      old_name = "index_#{from_prefix}_on_#{suffix}"
      new_name = "index_#{to_prefix}_on_#{suffix}"
      next if old_name == new_name
      next unless index_name_exists?(table_name, old_name)

      rename_index table_name, old_name, new_name
    end
  end
end
