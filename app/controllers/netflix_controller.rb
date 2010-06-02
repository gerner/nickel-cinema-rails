require "rubygems"
require "oauth"

class NetflixController < ApplicationController
  
  before_filter :login_or_redirect
  
  #this guy starts the oauth authorization process for netflix
  def new
    @consumer = oauth_consumer
  
    @request_token = @consumer.get_request_token
  
    session[:request_token]=@request_token.token
    session[:request_token_secret]=@request_token.secret
  
    @authorize_url = @request_token.authorize_url({
       :oauth_consumer_key => NETFLIX_KEY,
       :application_name => NETFLIX_APP_NAME,
       :oauth_callback => url_for(:controller => :netflix, :action => :create)
     })
  
    redirect_to @authorize_url
  end

  #this guy handles the callback from the netflix api, and saves the token/secret
  def create
    if !session[:request_token] || !session[:request_token_secret]
      flash[:error] = "There was an error authorizing Netflix"
      redirect_to root_url
    else
      @request_token=OAuth::RequestToken.new(oauth_consumer, session[:request_token],
        session[:request_token_secret])
      @access_token = @request_token.get_access_token
      
      @user = current_user
      @user.netflix_token = @access_token.token
      @user.netflix_token_secret = @access_token.secret
      @user.netflix_user_id = @access_token.params[:user_id]
      @user.save
      
      flash[:notice] = "Netflix successfully authorized"
      redirect_to root_url
    end
  end
  
  def destroy
    @user = current_user
    @user.netflix_token = nil
    @user.netflix_token_secret = nil
    @user.save
    redirect_to root_url
  end
  
  private
  def oauth_consumer
    @consumer = OAuth::Consumer.new(NETFLIX_KEY,NETFLIX_SECRET, {
           :site => "http://api.netflix.com",
           :request_token_url => "http://api.netflix.com/oauth/request_token",
           :access_token_url => "http://api.netflix.com/oauth/access_token",
           :authorize_url => "https://api-user.netflix.com/oauth/login",
           :application_name => NETFLIX_APP_NAME})
  end
end
