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
      available: 1
    )
  end

  it "increments available and publishes polish_work_done" do
    expect do
      post complete_polish_tracking_path(tracking)
    end.to change { tracking.reload.available }.from(1).to(2)

    expect(response).to redirect_to(root_path)

    message = karafka.produced_messages.last
    expect(message[:topic]).to eq("glass.work.done_polish")
    expect(message[:key]).to eq("123")

    payload = JSON.parse(message[:payload])
    expect(payload).to include(
      "event" => "polish_work_done",
      "tracking_id" => 123,
      "qty" => 1
    )
    expect(payload["event_id"]).to be_present
    expect(payload["occurred_at"]).to be_present
  end

  it "returns 404 for an unknown tracking" do
    post complete_polish_tracking_path(id: -1)

    expect(response).to have_http_status(:not_found)
  end
end
