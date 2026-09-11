require 'rails_helper'

RSpec.describe OutboxMessage, type: :model do
  it "defaults to pending with zero attempts" do
    event = described_class.create!(
      event_id: SecureRandom.uuid,
      topic: "glass.work.done_polish",
      event_name: "polish_work_done",
      payload: { event: "polish_work_done" }.to_json
    )

    expect(event.status).to eq("pending")
    expect(event.attempts).to eq(0)
  end

  it "rejects a duplicate event ID at the database level" do
    event_id = SecureRandom.uuid
    described_class.create!(event_id:, topic: "glass.work.done_polish", event_name: "polish_work_done", payload: "{}")

    expect do
      described_class.create!(event_id:, topic: "glass.work.done_polish", event_name: "polish_work_done", payload: "{}")
    end.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
