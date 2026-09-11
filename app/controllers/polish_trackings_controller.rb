class PolishTrackingsController < ApplicationController
  def index
    @polish_trackings = PolishTracking.order(:order_id)
  end

  def complete
    tracking = PolishTracking.find(params[:id])
    tracking.update!(completed: tracking.completed.to_i + 1)

    begin
      publish_polish_work_done(tracking)
    rescue StandardError => e
      Rails.logger.error("Failed to publish polish_work_done for tracking #{tracking.tracking_id}: #{e.message}")
      return redirect_to root_path, alert: "Work recorded, but the event could not be published."
    end

    redirect_to root_path, notice: "Completed one work for tracking #{tracking.tracking_id}."
  end

  private

  def publish_polish_work_done(tracking)
    Karafka.producer.produce_async(
      topic: "glass.work.done_polish",
      key: tracking.tracking_id.to_s,
      payload: {
        event: "polish_work_done",
        event_id: SecureRandom.uuid,
        tracking_id: tracking.tracking_id,
        qty: 1,
        occurred_at: Time.current.iso8601
      }.to_json
    )
  end
end
