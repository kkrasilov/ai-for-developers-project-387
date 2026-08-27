class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(_exception = nil)
    render json: { code: "not_found", message: "Resource not found" }, status: :not_found
  end

  def event_type_json(event_type)
    {
      id: event_type.id,
      name: event_type.name,
      description: event_type.description,
      duration_minutes: event_type.duration_minutes
    }
  end

  def booking_json(booking)
    {
      id: booking.id,
      event_type_id: booking.event_type_id,
      event_type_name: booking.event_type.name,
      guest_name: booking.guest_name,
      guest_email: booking.guest_email,
      start_at: booking.start_at.iso8601,
      end_at: booking.end_at.iso8601
    }
  end

  def slot_json(slot)
    {
      start_at: slot[:start_at].iso8601,
      end_at: slot[:end_at].iso8601
    }
  end
end
