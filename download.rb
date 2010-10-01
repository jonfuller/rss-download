require 'rubygems'
require 'yaml'
require 'rss'
require 'open-uri'

def load_yaml(filename)
  if File.exists? filename
    YAML.load_file filename
  else
    {}
  end
end

def hash_on(key, item_ary)
  item_ary = item_ary || []
  hash = {}
  item_ary.each{|item| hash[item[key]] = item}
  hash
end

from_config = hash_on('url', load_yaml('config.yml')['feeds'])
from_history = hash_on('url', load_yaml('history.yml')['feeds'])

feeds = from_config.each{|url, item| item.merge!(from_history[url] || {})}
def read_feed(url)
  content = open(url) { |s| s.read }
  RSS::Parser.parse(content, false)
end

feeds.each do |feed_url, feed|
  rss = read_feed(feed_url)
  puts feed_url, rss.items.first.date
end
