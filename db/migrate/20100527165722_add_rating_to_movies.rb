class AddRatingToMovies < ActiveRecord::Migration
  def self.up
    add_column :movies, :generic_rating, :integer
  end

  def self.down
    remove_column :movies, :generic_rating
  end
end
