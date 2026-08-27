class EventTypesController < ApplicationController
  def index
    event_types = EventType.order(:name)
    render json: event_types.map { |et| event_type_json(et) }
  end

  def show
    event_type = EventType.find(params[:id])
    render json: event_type_json(event_type)
  end
end
