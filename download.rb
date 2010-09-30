require 'rubygems'
require 'yaml'
require 'rss'
require 'open-uri'

url_template = 'http://eztvrss.it?show={#name}'


def load_yaml(filename)
  if File.exists? filename
    YAML.load_file filename
  else
    {}
  end
end

def show_hash(show_ary)
  show_ary = show_ary || []
  hash = {}
  show_ary.each{|show| hash[show['name']] = show}
  hash
end

config = load_yaml 'config.yml'
shows_from_history = show_hash(load_yaml('history.yml')['shows'])
shows_from_config = show_hash(config['shows'])

shows = shows_from_history.merge(shows_from_config)

shows.each do |show_name, show|
  puts show_name, show.inspect
end
