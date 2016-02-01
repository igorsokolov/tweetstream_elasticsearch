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

      #puts "#{tweet[:user][:screen_name]} - #{tweet}" 
      
      Tweet.set_index_from_time(tweet[:created_at])

      # Create tweet
      Tweet.create(tweet)
    end.on_enhance_your_calm do 
      puts "Waiting: 1 min"
      sleep 60
    end.on_limit do |skip_count|
      puts "Sleeping: #{skip_count+1}"
      sleep skip_count+1
    end
  end
end
