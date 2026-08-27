class EventType < ApplicationRecord
  has_many :bookings, dependent: :destroy

  validates :name, presence: true
  validates :description, presence: true
  validates :duration_minutes, presence: true,
                               numericality: { only_integer: true, greater_than: 0 }

  # Генерирует доступные слоты на ближайшие дни в рабочие часы (09:00-17:00),
  # исключая уже занятые бронированиями.
  def available_slots(from: Time.current, days: 7, day_start_hour: 9, day_end_hour: 17)
    booked = bookings.where("start_at >= ?", from).pluck(:start_at).to_set
    slots = []

    days.times do |day_offset|
      date = (from + day_offset.days).to_date
      cursor = Time.zone.local(date.year, date.month, date.day, day_start_hour)
      day_end = Time.zone.local(date.year, date.month, date.day, day_end_hour)

      while cursor + duration_minutes.minutes <= day_end
        finish = cursor + duration_minutes.minutes
        if cursor > from && !booked.include?(cursor)
          slots << { start_at: cursor, end_at: finish }
        end
        cursor = finish
      end
    end

    slots
  end
end
