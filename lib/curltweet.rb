require 'nokogiri'
require 'm3u8'
require 'open-uri'
require 'json'

@tweet = ARGV[0]
@token = @tweet.split('/')[5]
@link  = "https://twitter.com/i/videos/tweet/#{@token}"

def download_url
  # Grab and parse video HTML. Search result for script src
  doc = Nokogiri::HTML(open(@link))
  src = doc.at_css("script").to_s.split('"')[1]
  res = Nokogiri::HTML(open(src))

  # Grab auth token
  auth_token = res.to_s.match(/Bearer ([a-zA-Z0-9%-])+/).to_s

  # Talk to API
  api_link = "https://api.twitter.com/1.1/videos/tweet/config/#{@token}.json"
  api = open(api_link, 'Authorization' => auth_token)
  video_url = JSON.load(api)
  video_url = video_url['track']['playbackUrl']

  # Grab video
  video_res = open(video_url, 'Authorization' => auth_token)
  host = URI.parse(video_url).scheme + '://' + URI.parse(video_url).hostname


  exit(0)
end

download_url

# %x!/usr/bin/env curl -L -C - -o #{@link} #{download_url}!
