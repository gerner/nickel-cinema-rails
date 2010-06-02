class Showtime < ActiveRecord::Base
  validates_presence_of :showtime
  validates_uniqueness_of :showtime, :scope => [:movie_id, :theater_id]
  belongs_to :movie
  belongs_to :theater
  has_many :showtimes_for_zipcode
  
  def self.find_by_zipcode_and_showtime zipcode, options = {}
    desired_date = options[:date] || Time.now
    
    #first check if we have the showtimes already saved for this zipcode
    #if that turns up nothing then get showtimes from the web-service (and save it to the db)
    showtimes = []
    
    Showtime.transaction do
      logger.info("checking for showtimes")
      showtimes = Showtime.all(
        :include => [:movie, :theater],
        :joins => [:movie, :theater, :showtimes_for_zipcode],
        :conditions => {
          :showtime => desired_date..(desired_date + 1.days),
          :showtimes_for_zipcodes => {:zipcode => zipcode}}, 
        :order => "movies.generic_rating DESC, movie_id, theater_id, showtime ASC")
      logger.info("showtimes: #{showtimes.size}")
      if showtimes.size == 0
        logger.info("need to contact webservice")
        http = Net::HTTP.new("hurwi.net", 80)
        response = http.get("/map/parser2xml.php?loc=#{zipcode.to_i}", {"Referer" => "http://hurwi.net/map"})
        showtimes = parse_showtimes response.body, zipcode
        showtimes.sort { |x,y| y.movie.average_rating <=> x.movie.average_rating}
      end
      logger.info("parsed and created showtimes")
      #TODO: cache of showtimes stale? <-- we'll assume this never happens
    end
    return showtimes
  end
  
  #parses an XML response from the web service into an array of showtimes with their corresponding movies and theaters
  def self.parse_showtimes response, zipcode
    doc = Nokogiri::XML(response)
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
    final_showtimes = []
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
        
        final_showtimes += theater_showtimes.reverse
      end
    end
    final_showtimes
  end
end
