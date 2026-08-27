class CreateBookings < ActiveRecord::Migration[8.0]
  def change
    create_table :bookings do |t|
      t.references :event_type, null: false, foreign_key: true
      t.string :guest_name, null: false
      t.string :guest_email, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false

      t.timestamps
    end

    add_index :bookings, [:event_type_id, :start_at], unique: true
  end
end
