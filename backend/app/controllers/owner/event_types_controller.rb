class Owner::EventTypesController < ApplicationController
  def index
    event_types = EventType.order(:name)
    render json: event_types.map { |et| event_type_json(et) }
  end

  def create
    event_type = EventType.new(event_type_params)

    if event_type.save
      render json: event_type_json(event_type), status: :ok
    else
      render json: {
        code: "invalid_request",
        message: event_type.errors.full_messages.join(", ")
      }, status: :unprocessable_entity
    end
  end

  private

  def event_type_params
    params.permit(:name, :description, :duration_minutes)
  end
end
