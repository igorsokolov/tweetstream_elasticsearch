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

  settings :number_of_replicas => 0

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

  def self.search(options)
    search_string = options[:search]
    longitude     = options[:longitude]
    latitude      = options[:latitude]
    radius        = options[:radius]
    query = { 
      query: { 
        filtered: { 
          filter: { 
            geo_distance: {
              distance: "#{radius.to_i}mi",
              location: { lon: longitude.to_f, lat: latitude.to_f }
            }
          }
        }
      }, 
      sort: [
        created_at: {
          order: "desc" 
        }
      ], 
      size: 250
    }

    unless search_string.empty?
      query[:query][:filtered][:query] = { simple_query_string: { query: search_string } }
    end

    begin
      self.index_name = SEARCH_ALIAS
      Rails.logger.info "Query: #{query}"
      super(query)
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      Rails.logger.fatal("Search error: #{e.message}")
    end
  end

  def self.set_index_from_time(time)
    return nil unless time.kind_of?(Time)
    
    # We need to create Index by hour and add it to our Search Alias
    new_index_name = "#{Tweet::SEARCH_ALIAS}_#{time.strftime('%Y%m%d%H')}"

    unless self.index_name == new_index_name
      # If this hour index doesn't exists
      unless self.gateway.index_exists? index: new_index_name

        client = self.gateway.client
        
        # Create index
        self.gateway.create_index! index: new_index_name
        
        # Assign this index search alias
        client.indices.put_alias(index: new_index_name, name: SEARCH_ALIAS)
        
        # Delete index from more than 24 hours ago
        old_index_name = "#{SEARCH_ALIAS}_#{(time-24.hours).strftime('%Y%m%d%H')}"
        client.indices.delete index: old_index_name rescue nil
      end

      # Set index as working index 
      self.index_name = new_index_name 
    end
  end
end