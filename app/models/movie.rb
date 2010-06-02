require "rubygems"
require "nokogiri"
require "oauth"

class Movie < ActiveRecord::Base
  validates_presence_of :title
  validates_uniqueness_of :title
  has_many :showtimes
  has_many :theaters, :through => :showtimes, :uniq => true
  
  def rating
    custom_rating || average_rating
  end
  
  def custom_rating
    @custom_rating ||= nil
  end
  
  def custom_rating= rating
    @custom_rating = rating
  end
  
  def ref_url
    unless netflix_ref_url || title.nil?
      logger.info "need to lookup #{title} (#{netflix_ref_url})"
      lookup_and_save_netflix_catalog_info
    end
    netflix_ref_url
  end
  
  def info_url
    unless netflix_info_url || title.nil?
      logger.info "need to lookup #{title} (#{netflix_info_url})"
      lookup_and_save_netflix_catalog_info
    end
    netflix_info_url
  end
  
  def average_rating
    unless generic_rating || title.nil?
      logger.info "need to lookup #{title} (#{generic_rating})"
      lookup_and_save_netflix_catalog_info
    end
    generic_rating
  end
  
  private
  
  def get_movies_from_webservice zipcode
    http = Net::HTTP.new("hurwi.net", 80)
    response = http.get("/map/parser2xml.php?loc=#{zipcode.to_i}", {"Referer" => "http://hurwi.net/map"})
    raise "could not contact showtime service #{response.inspect}" unless response.instance_of? Net::HTTPSuccess
    doc = Nokogiri::XML(response.body)
    # response structured as:
    #- Theaters
    #  - Theater
    #    - Name
    #    - Movies
    #      - Movie
    #        - Name
    #        - Times: space separated list of times (no am/pm)
    #      - Movie
    #  - Theater
    
    # algo:
    # 1) pass over the showtimes, for each:
    # 2) get the movie and theater it's a showtime for
    # 3) stick the showtime info inside the related movie
    # 4) once we've got all the data, get the related movies and theaters
    # 5) get the associated movies and theaters (if we have em)
    # 6) if not, create new movies and theaters
    
    #will hold a structured tree of movies -> theaters -> showtimes
    movie_data = {}
    #will hold movie titles
    movies = {}
    #will hold theaters and their addresses
    theaters = {}
    
    times = doc.xpath("//Times")
    times.each do |time|
      movie = time.parent
      #logger.info "movie:"
      #logger.info movie.inspect
      #logger.info movie.to_s
      movie_title = movie.xpath("MovieName").first.text
      movies[movie_title] = movie_title
      
      theater = time.parent.parent.parent
      #logger.info "theater:"
      #logger.info theater.inspect
      #logger.info theater.to_s
      theater_name = theater.xpath("TheaterName").first.text
      theater_address = theater.xpath("Address").first.text
      theaters[theater_address] = theater_name
      showtimes = time.text
      
      movie_item = (movie_data[movie_title] ||= {:name => movie_title, :showtimes => {}})
      movie_item[:showtimes][theater_address] = showtimes
        
      logger.info "#{movie_title} #{theater_name} #{showtimes}"
    end
    relevant_movies = Movie.all(:conditions => ["title IN (?)", movies.keys])
    relevant_theaters = Theater.all(:conditions => ["address IN (?)", theaters.keys])
      
    theater_map = {}
      
    #fill out relevant_movies and relevant_theaters with movies and theaters as necessary
    relevant_movies.each do |movie|
      movies.delete movie.title
      theater_map
    end
    
    movies.each do |movie_title, v|
      logger.info "need to create a new movie: #{movie_title}"
      m = Movie.new
      m.title = movie_title
      m.save
      relevant_movies.push(m)
    end
    
    relevant_theaters.each do |theater|
      theaters.delete theater.address
      theater_map[theater.address] = theater
    end
    
    theaters.each do |theater_address, theater_name|
      logger.info "need to create a new theater: #{theater_name}"
      t = Theater.new
      t.name = theater_name
      t.address = theater_address
      t.save
      relevant_theaters.push(t)
      theater_map[t.address] = t
    end
    
    #at this point we've got all the relevant Movies and Theaters
    #now we can associate them with their showtimes
    #this is the final data
    relevant_movies.each do |movie|
      movie_data_item = movie_data[movie.title]
      #has structure: {:name => string, :showtimes => {theater_address => list_of_showtimes, ...}}
      movie_data_item[:showtimes].each do |address, showtimes|
        theater = theater_map[address]
        showtimes = showtimes.split
        
        theater_showtimes = []
        suffix = ""
        showtimes.reverse.each do |s|
          if s.end_with? "pm"
            t = Time.parse(s)
            suffix = "pm"
          elsif s.end_with? "am"
            t = Time.parse(s)
            suffix = "am"
          else
            t = Time.parse(s+suffix)
          end
          
          showtime = Showtime.first(
            :include => [:movie, :theater],
            :joins => [:movie, :theater],
            :conditions => {:theater_id => theater.id, :movie_id => movie.id, :showtime => t})
              
          if showtime.nil?
            showtime = Showtime.new
            showtime.showtime = t
            showtime.theater = theater
            showtime.movie = movie
            showtime.save
          end
          
          theater_showtimes.push showtime
          
          sfz = ShowtimesForZipcode.new
          sfz.showtime = showtime
          sfz.zipcode = zipcode
          sfz.save
        end
        
        theater.showtimes = theater_showtimes.reverse
        movie.theaters.push(theater)
      end
    end
    relevant_movies
  end
  
  def lookup_and_save_netflix_catalog_info options = {}
    dont_retry = options[:dont_retry]
    consumer = OAuth::Consumer.new(NETFLIX_KEY,NETFLIX_SECRET, {
               :site => "http://api.netflix.com",
               :request_token_url => "http://api.netflix.com/oauth/request_token",
               :access_token_url => "http://api.netflix.com/oauth/access_token",
               :authorize_url => "https://api-user.netflix.com/oauth/login",
               :application_name => NETFLIX_APP_NAME})
    
    logger.info "getting netflix info for #{title}"
    response = consumer.request(:get, "/catalog/titles?term=#{CGI::escape(title)}&max_results=1", nil, {:scheme => :query_string}, {"term" => title, "max_results" => "1"})
    case response
    when Net::HTTPSuccess
      logger.info "response for #{title}:"
      
      #parse the body looking for the info and ref urls, and save them
      doc = Nokogiri::XML(response.body)
      self.netflix_ref_url = doc.xpath("//id").first.text;
      self.netflix_info_url = doc.xpath("//link[@title='web page']").first.attributes["href"].text;
      self.generic_rating = doc.xpath("//average_rating").first.text.to_f
      
      logger.info "#{netflix_ref_url} #{netflix_info_url}"
      
      save
    else
      logger.info "error getting catalog results for #{title} #{response.inspect}"
      unless dont_retry
        Thread.sleep 1
        lookup_and_save_netflix_catalog_info options.merge({:dont_retry => true})
      else
        raise "error getting catalog results for #{title} #{response.inspect}"
      end
    end
  end
  
end
