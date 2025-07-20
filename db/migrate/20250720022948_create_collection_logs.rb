class CreateCollectionLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_logs do |t|
      t.string :region_code, null: false, limit: 2
      t.string :collection_type, null: false, default: 'all'
      t.integer :videos_collected, default: 0
      t.integer :api_calls_used, default: 0
      t.integer :status, default: 0
      t.text :error_message
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :collection_logs, [:region_code, :created_at]
    add_index :collection_logs, :status
    add_index :collection_logs, :started_at
  end
end
