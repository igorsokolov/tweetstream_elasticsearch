class Tweet
  include Elasticsearch::Persistence::Model

  index_name 'tweets'

  attribute :tweet_id,    String
  attribute :text,        String, mapping: { type: 'string', analyzer: 'keyword' }
  attribute :location,    Array, mapping: { type: 'geo_point' }
  attribute :created_at,  Time, default: Time.now, mapping: { type: 'date' }

end
