# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  geocode_ip_address
  before_filter :get_zipcode

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
  
  private
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.find(session[:current_user_id])
  end
  
  def admin?
    false
  end
  
  def login_or_redirect
    if !session[:current_user_id]
      flash[:error] = "You must be logged in first"
      redirect_to root_url
    end    
  end
  
  def admin_or_redirect
    if !admin?
      redirect_to root_url
    end
  end
  
  def current_user_or_redirect
    if !(admin? || (params[:id].to_i == session[:current_user_id]))
      redirect_to root_url
    end
  end
  
  def get_zipcode
    if params[:zipcode]
      session[:zipcode] = params[:zipcode].to_i
    end
    unless session[:zipcode]
      location = GeoKit::Geocoders::GoogleGeocoder.geocode("#{session[:geo_location].lat}, #{session[:geo_location].lng}")
      
      session[:zipcode] = location.zip || 98116
      logger.info "location: #{session[:geo_location].inspect}"
      logger.info "zip: #{location.zip}"
    end
  end
  
end
