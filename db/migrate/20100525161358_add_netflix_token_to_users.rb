class AddNetflixTokenToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :netflix_token, :string
  end

  def self.down
    remove_column :users, :netflix_token
  end
end
