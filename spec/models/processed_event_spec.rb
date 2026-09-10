require 'rails_helper'

RSpec.describe ProcessedEvent, type: :model do
  subject(:processed_event) { described_class.new(event_id: "0d55c41c-6396-4f24-9f9e-f6692799d4f4") }

  it "requires a unique event ID" do
    described_class.create!(event_id: processed_event.event_id)

    expect { processed_event.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
