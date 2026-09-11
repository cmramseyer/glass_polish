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

  describe "#pending" do
    it "returns available minus completed" do
      tracking = described_class.new(available: 5, completed: 2)

      expect(tracking.pending).to eq(3)
    end

    it "treats nil values as zero" do
      expect(described_class.new.pending).to eq(0)
      expect(described_class.new(available: 4).pending).to eq(4)
      expect(described_class.new(completed: 2).pending).to eq(-2)
    end
  end
end
