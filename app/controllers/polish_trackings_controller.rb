class PolishTrackingsController < ApplicationController
  def index
    @polish_trackings = PolishTracking.order(:order_id)
  end

  def complete
    tracking = PolishTracking.find(params[:id])
    event_id = SecureRandom.uuid

    PolishTracking.transaction do
      tracking.update!(completed: tracking.completed.to_i + 1)
      OutboxMessage.create!(
        event_id:,
        topic: "glass.work.done_polish",
        event_name: "polish_work_done",
        key: tracking.tracking_id.to_s,
        payload: {
          event: "polish_work_done",
          event_id:,
          tracking_id: tracking.tracking_id,
          qty: 1,
          occurred_at: Time.current.iso8601
        }.to_json
      )
    end

    begin
      OutboxPublisherJob.perform_later
    rescue StandardError => e
      Rails.logger.error("Failed to enqueue outbox publisher: #{e.message}")
    end

    redirect_to root_path, notice: "Completed one work for tracking #{tracking.tracking_id}."
  end
end
