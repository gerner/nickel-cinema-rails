class AddShowtimeIdIndexToShowtimesForZipcodes < ActiveRecord::Migration
  def self.up
    add_index :showtimes_for_zipcodes, :showtime_id
  end

  def self.down
    remove_index :showtimes_for_zipcodes, :column => :showtime_id
  end
end
