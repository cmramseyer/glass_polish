require "rails_helper"

RSpec.describe OutboxPublisherJob, type: :job do
  include Karafka::Testing::RSpec::Helpers

  let(:payload) do
    {
      event: "polish_work_done",
      event_id: "0d55c41c-6396-4f24-9f9e-f6692799d4f4",
      tracking_id: 123,
      qty: 1
    }.to_json
  end

  it "publishes pending messages and marks them published" do
    message = OutboxMessage.create!(
      event_id: "0d55c41c-6396-4f24-9f9e-f6692799d4f4",
      topic: "glass.work.done_polish",
      event_name: "polish_work_done",
      key: "123",
      payload:
    )

    described_class.perform_now

    produced = karafka.produced_messages
    expect(produced.size).to eq(1)
    expect(produced.last[:topic]).to eq("glass.work.done_polish")
    expect(produced.last[:key]).to eq("123")
    expect(produced.last[:payload]).to eq(payload)

    expect(message.reload.status).to eq("published")
    expect(message.reload.published_at).to be_present
  end

  it "skips already published messages" do
    OutboxMessage.create!(
      event_id: SecureRandom.uuid,
      topic: "glass.work.done_polish",
      event_name: "polish_work_done",
      payload: payload,
      status: "published",
      published_at: Time.current
    )

    described_class.perform_now

    expect(karafka.produced_messages).to be_empty
  end

  it "records the failure and raises for retry without marking published" do
    allow(Karafka.producer).to receive(:produce_sync).and_raise("boom")
    message = OutboxMessage.create!(
      event_id: SecureRandom.uuid,
      topic: "glass.work.done_polish",
      event_name: "polish_work_done",
      payload:
    )

    expect { described_class.perform_now }.to raise_error("boom")

    expect(message.reload.status).to eq("pending")
    expect(message.reload.attempts).to eq(1)
    expect(message.reload.last_error).to include("boom")
    expect(karafka.produced_messages).to be_empty
  end
end
