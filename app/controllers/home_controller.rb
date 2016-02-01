class HomeController < ApplicationController

  def index
    params[:longitude]  = params[:longitude].to_f == 0.0 ? -122.68 : params[:longitude].to_f
    params[:latitude]   = params[:latitude].to_f  == 0.0 ? 37.75   : params[:latitude].to_f
    params[:radius]     = params[:radius].to_i    == 0   ? 20      : params[:radius].to_f
    params[:search]     ||= ''

    @tweets = Tweet.search(params).to_a

    @hash = Gmaps4rails.build_markers(@tweets) do |tweet, marker|
      marker.lat tweet.location[1]
      marker.lng tweet.location[0]
      marker.infowindow render_to_string(:partial => "home/tweet", locals: { tweet: tweet})
    end
  end
end
