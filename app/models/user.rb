class User < ActiveRecord::Base
  validates_presence_of :name, :email, :password
  validates_uniqueness_of :name, :email
  def self.authenticate(email, password)
    User.first(:conditions => ["email = ? AND password = ?", email, password])
  end
  
  def netflix_access_token
    consumer = OAuth::Consumer.new(NETFLIX_KEY,NETFLIX_SECRET, {
               :site => "http://api.netflix.com",
               :request_token_url => "http://api.netflix.com/oauth/request_token",
               :access_token_url => "http://api.netflix.com/oauth/access_token",
               :authorize_url => "https://api-user.netflix.com/oauth/login",
               :application_name => NETFLIX_APP_NAME})
    OAuth::AccessToken.new(consumer, self.netflix_token, self.netflix_token_secret)
  end
end
