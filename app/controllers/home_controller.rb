class HomeController < ApplicationController

  def index
    @tweets = Tweet.search('', -122.68, 37.75, 30).to_a
  end

end
