require 'rubygems'
require 'yaml'
require 'rss'
require 'open-uri'
require 'logger'

class Downloader
  def initialize(working_dir = nil)
    @working_dir = File.expand_path(working_dir || File.dirname(__FILE__))

    unless File.exists?(@working_dir)
      puts "working directory does not exist.  creating."
      Dir.mkdir(@working_dir)
    end

    @logger = Logger.new(get_filename('log.log'), 'weekly')
    @logger.info("working directory: #{@working_dir}")
  end


  def download()
    unless File.exists?(config_file)
      @logger.error("config file doesn't exist.  exiting.")
      exit
    end
    
    config = load_yaml(config_file)
    history = load_yaml(history_file)

    feeds = load_feeds(config, history)
    download_location = config['download_location']

    @logger.info "download location: #{download_location}"
    feeds.each do |feed_url, feed|
      @logger.info "processing #{feed_url}"

      last_timestamp = Time.parse(feed['last_timestamp'] || '')

      rss = read_feed(feed_url)
      to_download = rss.items.select { |item| item.date > last_timestamp }
      @logger.info "  #{to_download.size} to download #{last_timestamp}"
      to_download.reverse.each_with_index do |item, i|
        download_item(item, i+1, to_download.size, download_location)
      end

      last_timestamp = to_download.first.date if to_download.any?

      history['feeds'] = update_history(history['feeds'], last_timestamp, feed_url)
    end

    @logger.info "done"
    save_yaml('history.yml', history)
  end

  private

  def config_file
    get_filename('config.yml')
  end

  def history_file
    get_filename('history.yml')
  end

  def get_filename(filename)
    File.join(@working_dir, filename)
  end

  def load_feeds(config_hash, history_hash)
    from_config = hash_on('url', config_hash['feeds'])
    from_history = hash_on('url', history_hash['feeds'])

    from_config.each{|url, item| item.merge!(from_history[url] || {})}
  end

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
    feed_history = feed_history || []
    new_history = feed_history.reject{|item| item['url'] == feed_url}

    history_item = {}
    history_item['url'] = feed_url
    history_item['last_timestamp'] = last_timestamp.to_s

    new_history << history_item
    new_history
  end

  def download_item(item, current, total, download_location)
    unless File.exists?(download_location)
      Dir.mkdir(download_location)
      @logger.info "  Download location #{download_location} does not exist, creating..."
    end
    @logger.info "  downloading #{current}/#{total} (#{item.date})"
    `wget -P "#{download_location}" "#{item.enclosure.url}"`
  end
end

Downloader.new().download
