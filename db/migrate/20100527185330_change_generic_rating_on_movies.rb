class ChangeGenericRatingOnMovies < ActiveRecord::Migration
  def self.up
	change_column :movies, :generic_rating, :float
  end

  def self.down
	change_column :movies, :generic_rating, :integer
  end
end
