require "cgi"
class Theater < ActiveRecord::Base
  validates_presence_of :name, :address
  validates_uniqueness_of :address
  has_many :showtimes
  has_many :movies, :through => :showtimes, :uniq => true
  
  def map_url
    "http://maps.google.com/maps?q=#{CGI::escape(self.address)}"
  end
end
