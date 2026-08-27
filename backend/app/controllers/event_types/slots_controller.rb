class EventTypes::SlotsController < ApplicationController
  def index
    event_type = EventType.find(params[:event_type_id])
    slots = event_type.available_slots
    render json: slots.map { |slot| slot_json(slot) }
  end
end
