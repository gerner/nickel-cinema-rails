class CreateShowtimes < ActiveRecord::Migration
  def self.up
    create_table :showtimes do |t|
      t.references :movie
      t.references :theater
      t.datetime :showtime

      t.timestamps
    end
  end

  def self.down
    drop_table :showtimes
  end
end
