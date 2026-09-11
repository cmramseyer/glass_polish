class OutboxMessage < ApplicationRecord
  validates :event_id, :topic, :event_name, :payload, presence: true
end
