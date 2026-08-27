class CreateEventTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :event_types do |t|
      t.string :name, null: false
      t.text :description, null: false, default: ""
      t.integer :duration_minutes, null: false

      t.timestamps
    end
  end
end
