require 'rails_helper'

RSpec.describe PolishTracking, type: :model do
  it "persists its tracking attributes" do
    polish_tracking = described_class.create!(
      order_id: 101,
      customer: "Acme Glass",
      product: "Window pane",
      tracking_id: 501,
      width: 100,
      height: 200,
      polish_type: "Edge polish",
      available: 3,
      completed: 1
    )

    expect(polish_tracking).to have_attributes(
      order_id: 101,
      customer: "Acme Glass",
      product: "Window pane",
      tracking_id: 501,
      width: 100,
      height: 200,
      polish_type: "Edge polish",
      available: 3,
      completed: 1
    )
  end
end
