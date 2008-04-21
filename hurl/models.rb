#--
# Copyright (c) 2007, 2008 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

##
# Models used by the Hurl application

module Hurl::Models

  ##
  # A Url class represents data and operations needed in creating and finding 
  # small URLs to be thrown from larger URLs.

  class Url < Base

    has_many :visits

    ##
    # The maximum power of the base 62 keys
    # 62 ** 5 == 916M or almost 1B

    MAX_POW = 5

    validates_uniqueness_of :key
    before_create :unique_key

    def validate_on_create
      begin
        uri = URI.parse(self.url)
        raise "http and https URLs only!" unless uri.scheme =~ /^http(s)?$/i
      rescue StandardError => err
        errors.add(:url, "invalid url: #{err}" )
      end
    end

    before_destroy do |url|
      raise ActiveRecord::ReadOnlyRecord.new("'it' token cannot be destroyed!") if 
        url.key.alphadecimal == 'it'
    end

    ##
    # token represenation of the key

    def token
      self.key.alphadecimal
    end

    ##
    # 

    def add_visit(env)
      options = {}
      options[:remote_addr] = env.REMOTE_ADDR if env.REMOTE_ADDR
      options[:referer] = env.HTTP_REFERER if env.HTTP_REFERER
      options[:user_agent] = env.HTTP_USER_AGENT if env.HTTP_USER_AGENT
      visits.create!(options)
    end

    ##
    # Look up the URL for the base62 token, increment the counter and a visit.

    def self.find_by_token(token, env)
      key = token.alphadecimal
      url = self.find(:first, :conditions => {:key => key})
      raise ActiveRecord::RecordNotFound.new("url for '#{key}' not found") unless url
      url.add_visit(env)
      url.increment!(:hits)
      url
    end

    ##
    # create a Url from +url+ and +remote_addr+

    def self.url_to_hurl(url, remote_addr)
      self.create(:url => url, :remote_addr => remote_addr)
    end

    private

    ##
    # choose a unique key for the Url

    def unique_key(count = self.class.count(:id), pow = nil)
      return if self.key #allow Url's to be created with create

      # determine the maximum key size based on the current number of Urls
      # we choose power that is more than double the current size of the table
      pow = (2..MAX_POW).detect{|i| count < (62**i)/2} unless pow

      k = rand(62**pow)
      unless Url.find_by_key(k)
        self.key = k
      else
        # calling recursively until finding a unique key is an idea taken from
        # robby russell's rubyurl
        unique_key(count, pow)
      end
    end

    ##
    # let URI.parse be our validator

    def valid_url?(url)
      begin
        uri = URI.parse(url)
        raise "http and https URLs only!" unless uri.scheme =~ /^http(s)?$/i
      rescue StandardError => err
        errors.add_to_base(err)
        return false
      end
      true
    end

  end

  class Visit < Base
    belongs_to :url
  end

  ##
  # Camping migration to create our database

  class CreateTheTable < V 0.1

    # XXX normally you could create the special 'it' default in the migration
    # but the base URL is dependant on the deployment so do it in the web's env
    # class Url < ActiveRecord::Base; end

    def self.up
      create_table :hurl_urls, :force => true do |t|
        t.column :key,         :integer, :null => false
        t.column :url,         :text,    :null => false
        t.column :hits,        :integer, :default => 0
        t.column :remote_addr, :string
        t.column :spam,        :boolean
        t.column :created_at,  :datetime
        t.column :updated_at,  :datetime
      end
      create_table :hurl_visits, :force => true do |t|
        t.column :url_id,      :integer, :null => false
        t.column :remote_addr, :string
        t.column :referer,     :text
        t.column :user_agent,  :string
        t.column :created_at,  :datetime
        t.column :updated_at,  :datetime
      end
      add_index :hurl_urls,   :key, :unique => true
      add_index :hurl_urls,   :remote_addr
      add_index :hurl_visits, :url_id

      # for XXX hax above
      # Url.create(:key => 'it'.alphadecimal, :url => 'http://hurl.it')
    end

    def self.down
      remove_index :hurl_urls, :key
      drop_table :hurl_urls
    end

  end

end

