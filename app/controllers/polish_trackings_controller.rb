class PolishTrackingsController < ApplicationController
  def index
    @polish_trackings = PolishTracking.order(:order_id)
  end
end
