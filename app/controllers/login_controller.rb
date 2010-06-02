class LoginController < ApplicationController
  def create
    if user = User.authenticate(params[:email], params[:password])
      # first clear the session
      reset_session
      # Save the user ID in the session so it can be used in
      # subsequent requests
      session[:current_user_id] = user.id
      session[:current_user_name] = user.name
      flash[:notice] = "You're logged in!"
      begin
        redirect_to :back
      rescue RedirectBackError
        redirect_to root_url
      end
    else
      flash[:error] = "Wrong username or password!"
      begin
        redirect_to :back
      rescue RedirectBackError
        redirect_to root_url
      end
    end
  end

  def destroy
    session[:current_user_id] = nil
    reset_session
    flash[:notice] = "You have successfully logged out"
    begin
      redirect_to :back
    rescue RedirectBackError
      redirect_to root_url
    end
  end

end
