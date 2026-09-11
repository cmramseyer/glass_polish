require "rails_helper"

RSpec.describe "Complete one work", type: :request do
  let!(:tracking) do
    PolishTracking.create!(
      tracking_id: 123,
      order_id: 456,
      customer: "Charlie",
      product: "Float 4mm. Clear",
      polish_type: "Edge polish",
      width: 1000,
      height: 500,
      total_item: 5,
      available: 1,
      completed: 0
    )
  end

  it "increments completed and queues polish_work_done in one transaction" do
    expect do
      post complete_polish_tracking_path(tracking)
    end.to change { tracking.reload.completed }.from(0).to(1)
      .and change(OutboxMessage, :count).by(1)

    expect(response).to redirect_to(root_path)
    expect(tracking.reload.available).to eq(1)

    outbox = OutboxMessage.last
    expect(outbox.topic).to eq("glass.work.done_polish")
    expect(outbox.event_name).to eq("polish_work_done")
    expect(outbox.key).to eq("123")
    expect(outbox.status).to eq("pending")

    payload = JSON.parse(outbox.payload)
    expect(payload).to include(
      "event" => "polish_work_done",
      "tracking_id" => 123,
      "qty" => 1
    )
    expect(payload["event_id"]).to eq(outbox.event_id)
    expect(payload["occurred_at"]).to be_present
  end

  it "enqueues the publisher job after commit" do
    allow(OutboxPublisherJob).to receive(:perform_later)

    post complete_polish_tracking_path(tracking)

    expect(OutboxPublisherJob).to have_received(:perform_later)
  end

  it "still redirects when the enqueue fails" do
    allow(OutboxPublisherJob).to receive(:perform_later).and_raise("boom")

    post complete_polish_tracking_path(tracking)

    expect(response).to redirect_to(root_path)
    expect(tracking.reload.completed).to eq(1)
    expect(OutboxMessage.count).to eq(1)
  end

  it "rolls back the increment when the outbox insert fails" do
    allow(OutboxMessage).to receive(:create!).and_raise("boom")

    expect do
      post complete_polish_tracking_path(tracking)
    end.to raise_error("boom")

    expect(tracking.reload.completed).to eq(0)
    expect(OutboxMessage.count).to eq(0)
  end

  it "returns 404 for an unknown tracking" do
    post complete_polish_tracking_path(id: -1)

    expect(response).to have_http_status(:not_found)
  end
end
