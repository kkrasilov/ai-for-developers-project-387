class Owner::BookingsController < ApplicationController
  def index
    bookings = Booking.includes(:event_type)
                      .where("start_at >= ?", Time.current)
                      .order(:start_at)
    render json: bookings.map { |b| booking_json(b) }
  end
end
