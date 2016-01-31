class User
  include Virtus.model

  attribute :screen_name
  attribute :name
  attribute :profile_image_url
end

class Tweet
  include Elasticsearch::Persistence::Model

  SEARCH_ALIAS = "#{Rails.env}_tweets"
  
  index_name SEARCH_ALIAS

  attribute :tweet_id,    String
  attribute :text,        String,                   mapping: { type: 'string', analyzer: 'snowball' }
  attribute :location,    Array,                    mapping: { 
                                                      type: 'geo_point', 
                                                      geohash: true, 
                                                      geohash_prefix: true,
                                                      geohash_precision: '1mi'
                                                    }
  attribute :created_at,  Time, default: Time.now,  mapping: { type: 'date' }
  attribute :user,        User,                     mapping: { type: 'object' }

  def self.search(search_string, lon, lat, radius)
    query_part =  if search_string.empty?
                    { match_all: {} }
                  else
                    { 
                      simple_query_string: {
                        query: search_string
                      }
                    }
                  end
    query = { 
      query: { 
        bool: { 
          must: [ 
            query_part
          ], 
          filter: { 
            geo_distance: {
              distance: "#{radius.to_i}mi",
              location: { lon: lon.to_f, lat: lat.to_f }
            }
          }
        }
      }, 
      sort: {
        created_at: {
          order: "desc" 
        }
      }, 
      size: 250
    }
    begin
      self.index_name = SEARCH_ALIAS
      p query
      super(query)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      Rails.logger.fatal("Search error: #{e.message}")
    end
  end
end

{ 
  query: { 
    bool: { 
      must: [ 
        { 
          match_all:{} 
        } 
      ], 
      filter: { 
        geo_distance: {
          distance:'100mi',
          location: { lon: 122.68, lat: 37.75 }
        }
      }
    }
  }, 
  sort: {
    created_at: {
      order: "desc" 
    }
  }, 
  size: 250
}