class RenameOutboxEventsToOutboxMessages < ActiveRecord::Migration[8.1]
  def change
    rename_table :outbox_events, :outbox_messages
    add_column :outbox_messages, :event_name, :string, default: "polish_work_done"
    change_column_null :outbox_messages, :event_name, false
    change_column_default :outbox_messages, :event_name, from: "polish_work_done", to: nil
  end
end
