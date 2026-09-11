require 'rails_helper'

RSpec.describe WorkCompletedConsumer, type: :consumer do
  subject(:consumer) { karafka.consumer_for('glass.work.queued_polish') }

  let(:event_id) { '0d55c41c-6396-4f24-9f9e-f6692799d4f4' }
  let(:payload) do
    {
      'event_id' => event_id,
      'tracking_id' => 123,
      'order_id' => 456,
      'customer_name' => 'Charlie',
      'product_name' => 'Float 4mm. Clear',
      'extra_data' => { 'polish_type' => 'Edge polish' },
      'width' => 1000,
      'height' => 500,
      'total_line' => 5,
      'done' => 1,
      'occurred_at' => '2026-09-10T22:30:00Z'
    }
  end

  it 'creates a tracking from a new event' do
    karafka.produce(payload.to_json, key: event_id)

    expect { consumer.consume }.to change(PolishTracking, :count).by(1)
      .and change(ProcessedEvent, :count).by(1)

    expect(PolishTracking.last).to have_attributes(
      tracking_id: 123,
      order_id: 456,
      customer: 'Charlie',
      product: 'Float 4mm. Clear',
      polish_type: 'Edge polish',
      width: 1000,
      height: 500,
      total_item: 5,
      available: 1,
      completed: 0
    )
  end

  it 'updates only available when the tracking exists' do
    tracking = PolishTracking.create!(
      tracking_id: 123,
      customer: 'Original customer',
      product: 'Original product',
      polish_type: 'Original polish',
      available: 0,
      completed: 8
    )
    karafka.produce(payload.to_json, key: event_id)

    expect { consumer.consume }.to change { tracking.reload.available }.from(0).to(1)

    expect(tracking).to have_attributes(
      customer: 'Original customer',
      product: 'Original product',
      polish_type: 'Original polish',
      completed: 8
    )
  end

  it 'ignores a duplicate event' do
    karafka.produce(payload.to_json, key: event_id)
    consumer.consume
    karafka.produce(payload.to_json, key: event_id)

    expect { consumer.consume }.not_to change(PolishTracking, :count)
    expect(ProcessedEvent.where(event_id:).count).to eq(1)
  end

  it 'rejects a message whose key differs from its event ID' do
    karafka.produce(payload.to_json, key: 'different-event-id')

    expect { consumer.consume }.to raise_error(ArgumentError, 'Kafka key must match event_id')
    expect(ProcessedEvent.count).to eq(0)
    expect(PolishTracking.count).to eq(0)
  end

  it 'creates a tracking without a polish type' do
    payload_without_polish_type = payload.merge('extra_data' => {})
    karafka.produce(payload_without_polish_type.to_json, key: event_id)

    expect { consumer.consume }.to change(PolishTracking, :count).by(1)
      .and change(ProcessedEvent, :count).by(1)
    expect(PolishTracking.last.polish_type).to be_nil
  end
end
