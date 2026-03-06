class CreateCorrespondentsAndLinks < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationChild < ApplicationRecord
    self.table_name = "children"
  end

  class MigrationCommunication < ApplicationRecord
    self.table_name = "communications"
  end

  class MigrationArtifact < ApplicationRecord
    self.table_name = "artifacts"
  end

  class MigrationCorrespondent < ApplicationRecord
    self.table_name = "correspondents"
  end

  class MigrationCommunicationCorrespondent < ApplicationRecord
    self.table_name = "communication_correspondents"
  end

  def up
    create_table :correspondents do |t|
      t.references :user, foreign_key: true, index: { unique: true }
      t.string :name
      t.string :email
      t.string :phone
      t.timestamps
    end

    add_index :correspondents, :email

    create_table :communication_correspondents do |t|
      t.references :communication, null: false, foreign_key: true
      t.references :correspondent, null: false, foreign_key: true
      t.string :role
      t.timestamps
    end

    add_index :communication_correspondents, [:communication_id, :correspondent_id], unique: true, name: "idx_comm_corr_unique"

    add_reference :artifacts, :communication, foreign_key: true

    backfill_user_correspondents!
    backfill_communication_correspondents!
    backfill_artifact_communications!

    change_column_null :artifacts, :communication_id, false
  end

  def down
    remove_reference :artifacts, :communication, foreign_key: true
    drop_table :communication_correspondents
    drop_table :correspondents
  end

  private

  def backfill_user_correspondents!
    MigrationUser.find_each do |user|
      MigrationCorrespondent.find_or_create_by!(user_id: user.id) do |correspondent|
        correspondent.email = user.email
        correspondent.name = user.email
      end
    end
  end

  def backfill_communication_correspondents!
    MigrationCommunication.find_each do |communication|
      correspondent = if communication.from_email.present?
        MigrationCorrespondent.find_or_create_by!(email: communication.from_email.downcase) do |record|
          record.name = communication.from_name.presence || communication.from_email
        end
      else
        child = MigrationChild.find_by(id: communication.child_id)
        next unless child

        MigrationCorrespondent.find_or_create_by!(email: "parent-#{child.parent_id}@unknown.local") do |record|
          record.name = "Parent #{child.parent_id}"
        end
      end

      MigrationCommunicationCorrespondent.find_or_create_by!(
        communication_id: communication.id,
        correspondent_id: correspondent.id
      )
    end
  end

  def backfill_artifact_communications!
    MigrationArtifact.find_each do |artifact|
      communication = MigrationCommunication.find_or_create_by!(
        child_id: artifact.child_id,
        source: artifact.source,
        from_email: artifact.from_email,
        from_name: artifact.from_name,
        subject: artifact.subject,
        received_at: artifact.occurred_at || artifact.captured_at
      ) do |record|
        record.body_text = artifact.body_text
        record.body_html = artifact.body_html
        record.raw_payload = artifact.raw_payload || {}
        record.ai_status = artifact.ai_status.presence || "pending"
      end

      if communication.from_email.present?
        correspondent = MigrationCorrespondent.find_or_create_by!(email: communication.from_email.downcase) do |record|
          record.name = communication.from_name.presence || communication.from_email
        end

        MigrationCommunicationCorrespondent.find_or_create_by!(
          communication_id: communication.id,
          correspondent_id: correspondent.id
        )
      end

      artifact.update_columns(communication_id: communication.id)
    end
  end
end
