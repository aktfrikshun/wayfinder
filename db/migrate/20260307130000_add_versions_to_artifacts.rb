class AddVersionsToArtifacts < ActiveRecord::Migration[8.1]
  def change
    add_column :artifacts, :extraction_version, :integer, null: false, default: 1
    add_column :artifacts, :classification_version, :integer, null: false, default: 1
    add_column :artifacts, :insight_version, :integer, null: false, default: 1
    add_column :artifacts, :last_processed_at, :datetime
  end
end
