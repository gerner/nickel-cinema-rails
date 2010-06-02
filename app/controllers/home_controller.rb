require 'rubygems'
require 'geokit'

class HomeController < ApplicationController
  
  def index
    
    showtimes = Showtime.find_by_zipcode_and_showtime session[:zipcode]
    
    #showtimes will come back a pretty flat model result
    #our view code will be much nicer if we can structure this data a little bit more
    #below we make a hierarchy movie => theaters => showtimes    
    @movies = []
    last_movie = {:movie => nil}
    last_theater = {:theater => nil}
    showtimes.each do |showtime|
      unless showtime.movie == last_movie[:movie]
        last_movie = {:movie => showtime.movie, :theaters => []}
        @movies.push last_movie
        last_theater = {:theater => nil}
      end
      
      unless showtime.theater == last_theater[:theater]
        last_theater = {:theater => showtime.theater, :showtimes => []}
        last_movie[:theaters].push last_theater
      end
      
      last_theater[:showtimes].push showtime
      
    end
  end
  
  def attend
    showtime = Showtime.find(params[:id]) 
    flash[:notice] = "you've attended '#{showtime.movie.title}' at #{showtime.showtime} at #{showtime.theater.name}!"
    redirect_to root_url
  end

end
