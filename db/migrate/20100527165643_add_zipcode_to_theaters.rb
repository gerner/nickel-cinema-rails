class AddZipcodeToTheaters < ActiveRecord::Migration
  def self.up
    add_column :theaters, :zipcode, :integer
  end

  def self.down
    remove_column :theaters, :zipcode
  end
end
