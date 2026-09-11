# frozen_string_literal: true

class WorkCompletedConsumer < ApplicationConsumer
  def consume
    messages.each { |message| process(message) }
  end

  private

  def process(message)
    payload = message.payload
    event_id = payload.fetch("event_id")

    raise ArgumentError, "Kafka key must match event_id" unless message.key == event_id

    PolishTracking.transaction do
      ProcessedEvent.create!(event_id:)

      tracking = PolishTracking.find_by(tracking_id: payload.fetch("tracking_id"))
      if tracking
        tracking.update!(available: payload.fetch("done"))
      else
        PolishTracking.create!(
          tracking_id: payload.fetch("tracking_id"),
          order_id: payload.fetch("order_id"),
          customer: payload.fetch("customer_name"),
          product: payload.fetch("product_name"),
          polish_type: payload.fetch("extra_data", {}).fetch("polish_type", nil),
          width: payload.fetch("width"),
          height: payload.fetch("height"),
          total_item: payload.fetch("total_line"),
          available: payload.fetch("done")
        )
      end
    end
  rescue ActiveRecord::RecordNotUnique
    # The unique inbox record means this delivery was already applied.
  end
end
