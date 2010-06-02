class AddIndxesForShowtimes < ActiveRecord::Migration
  def self.up
    add_index :showtimes, :showtime
    add_index :showtimes_for_zipcodes, :zipcode
  end

  def self.down
    remove_index :showtimes, :column => :showtime
    remove_index :showtimes_for_zipcodes, :column => :zipcode
  end
end
