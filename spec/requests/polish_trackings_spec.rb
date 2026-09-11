require "rails_helper"

RSpec.describe "Polish trackings", type: :request do
  it "shows tracking records at the root path" do
    PolishTracking.create!(
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

    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Order ID", "Window pane", "Edge polish", "Pending")
    expect(response.body).to include("<td>2</td>")
    expect(response.body).not_to include("Acme Glass")
  end
end
