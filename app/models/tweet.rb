class Tweet
  include Elasticsearch::Persistence::Model

  SEARCH_ALIAS = "#{Rails.env}_tweets"
  
  index_name SEARCH_ALIAS

  attribute :tweet_id,    String
  attribute :text,        String,                   mapping: { type: 'string', analyzer: 'keyword' }
  attribute :location,    Array,                    mapping: { type: 'geo_point' }
  attribute :created_at,  Time, default: Time.now,  mapping: { type: 'date' }

  def self.search(*args)
    self.index_name = SEARCH_ALIAS
    super
  end
end
