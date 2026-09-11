class CreateOutboxEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :outbox_events do |t|
      t.string :event_id, null: false
      t.string :topic, null: false
      t.string :key
      t.text :payload, null: false
      t.string :status, null: false, default: "pending"
      t.integer :attempts, null: false, default: 0
      t.text :last_error
      t.datetime :published_at

      t.timestamps
    end

    add_index :outbox_events, :event_id, unique: true
    add_index :outbox_events, %i[status id]
  end
end
