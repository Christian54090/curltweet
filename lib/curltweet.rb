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

  # Grab auth token
  auth_token = src.to_s.match(/Bearer ([a-zA-Z0-9%-])+/).to_s

  # Talk to API, ask it nicely for the video url
  api_link = "https://api.twitter.com/1.1/videos/tweet/config/#{@token}.json"
  api = open(api_link, 'Authorization' => auth_token)
  video_url = JSON.load(api)['track']['playbackUrl']

  # Grab video
  video_res = open(video_url, 'Authorization' => auth_token)
  host = URI.parse(video_url).scheme + '://' + URI.parse(video_url).hostname

  # Parse the video
  video_parse = M3u8::Playlist.read(video_res)

  video_parse.items.each do |video|
    play_url = host + video.uri
    play_res = open(play_url)

    play_parse = M3u8::Playlist.read(play_res)

    content = ''

    play_parse.items.each do |segment|
      uri = segment.to_s.split(',')[1].strip
      file = open(host + uri)
      suffix = uri.split('/')[-1]

      File.open(file).each_line{ |line| content += line }
    end

    # Compile video into one file and download it
    File.open("#{@author}_#{@token}_#{video.resolution}.ts", 'w'){ |f|
      f.write(content)
    }

  end
end

download_url
