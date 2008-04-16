#--
# Copyright (c) 2007, 2008 by Mike Mondragon (mikemondragon@gmail.com)
#
# Please see the README.txt file for licensing information.
#++

##
# Models used by the Hurl application

module Hurl::Models

  ##
  # A Url class represents data and operations needed to creating
  # and finding small URLs to be thrown from larger URLs.

  class Url < Base

    ##
    # The maximum power of the base 62 keys

    MAX_POW = 5 # 62 ** 5 == 916M or almost 1B

    validate :valid_url?
    validates_uniqueness_of :key
    before_create :unique_key

    def before_destroy
      # we don't want to destroy the special 'it' token , i.e. key 2783
      raise ActiveRecord::RecordNotFound.new("'it' token cannot be destroyed!") if 
        self.key.alphadecimal == 'it'
    end

    ##
    # token represenation of the key

    def token
      self.key.alphadecimal
    end

    class << self

      ##
      # Look up the URL for the base62 token.
      # Each lookup will increment the counter.
  
      def find_by_token(token)
        key = token.alphadecimal
        url = self.find(:first, :cnditions => {:key => key})
        raise ActiveRecord::RecordNotFound.new("url for '#{key}' not found") unless url
        url.increment!(:hits)
        url
      end
    end

    private

    ##
    # choose a unique key for the Url

    def unique_key(count = self.class.count(:id), pow = nil)
      # determine the maximum key size based on the current number of Urls
      # we choose power that is more than double the current size of the table
      pow = (2..MAX_POW).detect{|i| count < (62**i)/2} unless pow

      key = rand(62**pow)
      unless Url.find_by_key(key)
        self.key = key
      else
        # calling recursively until finding a unique key is an idea taken from
        # robby russell's rubyurl
        unique_key(count, pow)
      end
    end

    ##
    # let URI.parse be our validator

    def valid_url?
      begin
        URI.parse(self.url)
      rescue URI::InvalidURIError => err
        errors.add_to_base(err)
      end
    end

  end

  ##
  # Camping migration to create our database

  class CreateTheTable < V 0.1

    def self.up
      create_table :hurl_urls, :force => true do |t|
        t.column :key,         :integer, :null => false
        t.column :url,         :text,    :null => false
        t.column :hits,        :integer, :default => 0
        t.column :created_at,  :datetime
        t.column :updated_at,  :datetime
      end
      add_index :hurl_urls, :key, :unique => true
    end

    def self.down
      remove_index :hurl_urls, :key
      drop_table :hurl_urls
    end

  end

end

