namespace :twitter do
  desc "Ingest twitter locations stream for whole earth surface"
  task ingest: :environment do
    p 'Started'
    TweetStream::Client.new.locations(-180.0,-85.0, 180.0,85.0) do |status|
      # Tweet data
      tweet = {}
      tweet[:location] =  if !status.geo.nil?
                            status.geo.coordinates.reverse # Coordinates of tweet location
                          else
                            bbox = status.place.bounding_box.coordinates[0] # Place of tweet
                            [(bbox[0][0]+bbox[2][0])/2, (bbox[0][1]+bbox[1][1])/2]
                          end
      tweet[:created_at] = status.created_at
      tweet[:text] = status.text
      tweet[:tweet_id] = status.id.to_s
      tweet[:user] = {
        screen_name: status.user.screen_name,
        name: status.user.name,
        profile_image_url: status.user.profile_image_url
      }

      # Index managment. 
      # We need to create Index by hour and add it to our Search Alias
      index_name = "#{Tweet::SEARCH_ALIAS}_#{tweet[:created_at].strftime('%Y%m%d%H')}"

      # If this hour index doesn't exists
      unless Tweet.gateway.index_exists? index: index_name
        # Create index
        Tweet.gateway.create_index! index: index_name, force: true
        # Assign this index search alias
        Tweet.gateway.client.indices.put_alias(index: index_name, name: Tweet::SEARCH_ALIAS)
        
        # Delete index from more than 24 hours ago
        old_index_name = "#{Tweet::SEARCH_ALIAS}_#{(tweet[:created_at]-24.hours).strftime('%Y%m%d%H')}"
        Tweet.gateway.client.indices.delete index: old_index_name rescue nil
      end

      # Set index as working index for this hour
      Tweet.index_name = index_name unless Tweet.index_name == index_name
      
      # puts "#{tweet[:user][:screen_name]} - #{tweet}" 

      # Create tweet
      Tweet.create(tweet)
    end.on_enhance_your_calm do 
      puts "Wait: 1 min"
      sleep 60
    end.on_limit do |skip_count|
      puts "Sleeping: #{skip_count+1}"
      sleep skip_count+1
    end
  end
end
