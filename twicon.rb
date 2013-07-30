require 'dalli'
require 'nokogiri'
require 'open-uri'
require 'sinatra'

class Twicon < Sinatra::Base
  configure do
    set :cache, Dalli::Client.new(nil, expires_in: 60)
  end

  helpers do
    def avatar_url(username)
      url = cache("avatar:#{username}") do
        node = html(username).css('.size73').first
        node ? node['src'] : 404
      end
      halt_if_integer(url)
    end

    def sized_avatar_url(username, size=nil)
      size = size ? '_' + size : ''
      avatar_url(username).gsub(/_bigger(?:(?=\.(?:jpe?g|gif|png))|$)/i, size)
    end

    def header_url(username)
      url = cache("header:#{username}") do
        node = html(username).css('.profile-header-inner').first
        node ? node['data-background-image'].gsub(/\Aurl\('|'\)\z/, '') : 404
      end
      halt_if_integer(url)
    end

    def html(username)
      Nokogiri.HTML(open("https://twitter.com/#{username}").read)
    rescue OpenURI::HTTPError => e
      halt e.message[0...3].to_i
    end

    def cache(key, &block)
      settings.cache.fetch(key, &block)
    end

    def halt_if_integer(value)
      halt value if value.is_a? Integer
      value
    end
  end

  get '/' do
    redirect 'https://github.com/wktk/twicon'
  end

  get '/favicon.ico' do
    redirect to '/wktk/mini'
  end

  get '/:username/header' do
    redirect header_url(params[:username])
  end

  get '/:username/?:size?' do
    redirect sized_avatar_url(params[:username], params[:size])
  end
end
