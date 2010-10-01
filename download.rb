require 'rubygems'
require 'yaml'
require 'rss'
require 'open-uri'
require 'logger'


def load_yaml(filename)
  if File.exists? filename
    YAML.load_file filename
  else
    {}
  end
end

def save_yaml(filename, hash)
  File.open(filename, 'w') do |out|
    YAML.dump(hash, out)
  end
end

def hash_on(key, item_ary)
  item_ary = item_ary || []
  hash = {}
  item_ary.each{|item| hash[item[key]] = item}
  hash
end

def read_feed(url)
  content = open(url) { |s| s.read }
  RSS::Parser.parse(content, false)
end

def update_history(feed_history, last_timestamp, feed_url)
  new_history = feed_history.reject{|item| item['url'] == feed_url}

  history_item = {}
  history_item['url'] = feed_url
  history_item['last_timestamp'] = last_timestamp.to_s

  new_history << history_item
  new_history
end

def download_item(item, i)
  logger.info "  downloading #{i+1}/#{to_download.size} (#{item.date})"
end

logger = Logger.new('downloader.log', 'weekly')

config = load_yaml('config.yml')
history = load_yaml('history.yml')

from_config = hash_on('url', config['feeds'])
from_history = hash_on('url', history['feeds'])

feeds = from_config.each{|url, item| item.merge!(from_history[url] || {})}

feeds.each do |feed_url, feed|
  logger.info "processing #{feed_url}"

  last_timestamp = Time.parse(feed['last_timestamp'] || '')

  rss = read_feed(feed_url)
  to_download = rss.items.select { |item| item.date > last_timestamp }
  logger.info "  #{to_download.size} items to download since #{last_timestamp}"
  to_download.reverse.each_with_index do |item, i|
    download_items(item, i)
  end

  if (to_download.any?)
    history['feeds'] = update_history(history['feeds'], to_download.first.date, feed_url)
  end
end
logger.info "done"
save_yaml('history.yml', history)
