require 'rails_helper'

RSpec.describe Tweet, type: :model, elasticsearch: true do
  before do
    # Create and destroy Elasticsearch indexes
    # between tests to eliminate test pollution
    Tweet.index_name = Tweet::SEARCH_ALIAS + '1'
    Tweet.gateway.create_index! index: Tweet::SEARCH_ALIAS + '1'
    Tweet.gateway.client.indices.put_alias index: Tweet.index_name, name: Tweet::SEARCH_ALIAS

    tweet_params = {
      text: 'Test tweet',
      location: [-122.4167, 37.7833],
      created_at: Time.now,
      user: {
        name: 'Test 1',
        screen_name: 'test1'
      }
    }

    Tweet.create(tweet_params)
    sleep 1
  end

  after do
    Tweet.gateway.client.indices.delete index: Tweet::SEARCH_ALIAS + '1'
  end

  describe '.search' do
    context 'location only' do
      it 'returns tweet when location matches' do
        result = Tweet.search(search: '', longitude: -122.416, latitude: 37.783, radius: 20).to_a
        expect(result.count).to eq 1
        expect(result.first.text).to eq 'Test tweet'
        expect(result.first.location).to eq [-122.4167, 37.7833]
        expect(result.first.user.screen_name).to eq 'test1'
      end
    end
    context 'location with text' do
      it 'returns tweet when location matches and text' do
        result = Tweet.search(search: 'tweet', longitude: -122.416, latitude: 37.783, radius: 20).to_a
        expect(result.count).to eq 1
        expect(result.first.text).to eq 'Test tweet'
        expect(result.first.location).to eq [-122.4167, 37.7833]
        expect(result.first.user.screen_name).to eq 'test1'
      end
    end
  end

  describe '.set_index_from_time' do
    it 'sets index for current hour and add alias to it' do
      Tweet.set_index_from_time(Time.now)
      index_name = 'test_tweets_' + Time.now.strftime('%Y%m%d%H')
      expect(Tweet.gateway.index_exists?(index: index_name)).to be_truthy
      expect(Tweet.index_name).to eq index_name
      Tweet.gateway.client.indices.delete(index: index_name)
      Tweet.index_name = Tweet::SEARCH_ALIAS
    end
  end
  
end
