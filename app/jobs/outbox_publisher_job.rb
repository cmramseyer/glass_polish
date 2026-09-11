# frozen_string_literal: true

# Publishes pending outbox messages to Kafka. Delivery is at-least-once:
# consumers must deduplicate by the event_id carried in each payload.
class OutboxPublisherJob < ApplicationJob
  queue_as :default

  def perform(batch_size = 100)
    OutboxMessage.where(status: "pending").order(:id).limit(batch_size).each do |message|
      publish(message)
    end
  end

  private

  def publish(message)
    Karafka.producer.produce_sync(
      topic: message.topic,
      key: message.key,
      payload: message.payload
    )
    message.update!(status: "published", published_at: Time.current)
  rescue StandardError => e
    message.update!(attempts: message.attempts + 1, last_error: "#{e.class}: #{e.message}")
    raise
  end
end
