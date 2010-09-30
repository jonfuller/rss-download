require 'rubygems'
require 'yaml'

def load_yaml(filename)
  if File.exists? filename
    YAML.load_file filename
  else
    {}
  end
end

def hash_on(item_ary)
  item_ary = item_ary || []
  hash = {}
  item_ary.each{|item| hash[item['name']] = item}
  hash
end

config = load_yaml 'config.yml'

from_history = hash_on('name', load_yaml('history.yml')['items'])
from_config = hash_on(config['items'])

url_template = config['url_template'] | 'http://eztvrss.it?show={#name}'

items = from_history.merge(from_config)

items.each do |show_name, show|
  puts show_name, show.inspect
end
