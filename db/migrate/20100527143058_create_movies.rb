class CreateMovies < ActiveRecord::Migration
  def self.up
    create_table :movies do |t|
      t.string :title
      t.string :netflix_ref_url
      t.string :netflix_info_url
      t.int :custom_rating
      t.int :generic_rating

      t.timestamps
    end
  end

  def self.down
    drop_table :movies
  end
end
