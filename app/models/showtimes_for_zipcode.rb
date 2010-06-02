class ShowtimesForZipcode < ActiveRecord::Base
  belongs_to :showtime
  validates_uniqueness_of :zipcode, :scope => :showtime_id
end
