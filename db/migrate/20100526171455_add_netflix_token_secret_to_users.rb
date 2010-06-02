class AddNetflixTokenSecretToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :netflix_token_secret, :string
  end

  def self.down
    remove_column :users, :netflix_token_secret
  end
end
