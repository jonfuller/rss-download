require 'rubygems'
require 'yaml'

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

feeds.each do |show_url, show|
  puts show_url, show.inspect
end
