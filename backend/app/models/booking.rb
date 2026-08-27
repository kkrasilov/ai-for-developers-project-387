class Booking < ApplicationRecord
  belongs_to :event_type

  validates :guest_name, presence: true
  validates :guest_email, presence: true,
                          format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :start_at, presence: true
  validates :start_at, uniqueness: { scope: :event_type_id, message: "slot already booked" }

  before_validation :set_end_at

  private

  def set_end_at
    return if start_at.blank? || event_type.blank?

    self.end_at = start_at + event_type.duration_minutes.minutes
  end
end
