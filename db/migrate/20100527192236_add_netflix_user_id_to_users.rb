class AddNetflixUserIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :netflix_user_id, :string
  end

  def self.down
    remove_column :users, :netflix_user_id
  end
end
