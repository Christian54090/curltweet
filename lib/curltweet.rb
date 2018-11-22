require 'nokogiri'
require 'm3u8'
require 'open-uri'
require 'json'

@tweet = ARGV[0]
@token = @tweet.split('/')[5]
@author = @tweet.split('/')[3]
@link = "https://twitter.com/i/videos/tweet/#{@token}"

def download_url
  # Grab and parse video HTML. Search result for script src
  doc = Nokogiri::HTML(open(@link))
  find_src = doc.at_css('script').to_s.split('"')[1]
  src = Nokogiri::HTML(open(find_src))

  # Grab auth token. regex taken from github...twitter-video-downloader
  auth_token = src.to_s.match(/Bearer ([a-zA-Z0-9%-])+/).to_s

  # Talk to API, ask it nicely for the video url
  api_link = "https://api.twitter.com/1.1/videos/tweet/config/#{@token}.json"
  api = open(api_link, 'Authorization' => auth_token)
  pl_url = JSON.load(api)['track']['playbackUrl']

  # Grab playlist (playlist contains all video resolutions)
  pl_response = open(pl_url, 'Authorization' => auth_token)
  host = URI.parse(pl_url).scheme + '://' + URI.parse(pl_url).hostname

  # Parse the playlist
  pl_parse = M3u8::Playlist.read(pl_response)

  pl_parse.items.each do |video|
    video_response = open(host + video.uri)
    video_parse = M3u8::Playlist.read(video_response)
    content = ''

    video_parse.items.each do |segment|
      segment_uri = segment.to_s.split(',')[1].strip
      file = open(host + segment_uri)

      File.open(file).each_line{ |line| content += line }
    end

    # Compile video into one file and download it
    File.open("#{@author}_#{@token}_#{video.resolution}.ts", 'w'){ |f|
      f.write(content)
    }

  end
end

download_url
