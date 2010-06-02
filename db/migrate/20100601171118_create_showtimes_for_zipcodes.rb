class CreateShowtimesForZipcodes < ActiveRecord::Migration
  def self.up
    create_table :showtimes_for_zipcodes do |t|
      t.references :showtime
      t.integer :zipcode

      t.timestamps
    end
  end

  def self.down
    drop_table :showtimes_for_zipcodes
  end
end
