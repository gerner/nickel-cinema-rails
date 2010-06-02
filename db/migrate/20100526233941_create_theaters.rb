class CreateTheaters < ActiveRecord::Migration
  def self.up
    create_table :theaters do |t|
      t.string :name
      t.int :zipcode
      t.string :phone_number
      t.string :address

      t.timestamps
    end
  end

  def self.down
    drop_table :theaters
  end
end
