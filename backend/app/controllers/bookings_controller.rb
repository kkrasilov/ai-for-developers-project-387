class BookingsController < ApplicationController
  def create
    event_type = EventType.find(booking_params[:event_type_id])
    booking = event_type.bookings.new(
      guest_name: booking_params[:guest_name],
      guest_email: booking_params[:guest_email],
      start_at: booking_params[:start_at]
    )

    if booking.save
      render json: booking_json(booking), status: :ok
    elsif booking.errors.added?(:start_at, "slot already booked")
      render json: { code: "conflict", message: "This slot is already booked" },
             status: :conflict
    else
      render json: {
        code: "invalid_slot",
        message: booking.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  private

  def booking_params
    params.permit(:event_type_id, :start_at, :guest_name, :guest_email)
  end
end
