#--
# Copyright (c) 2007 by Mike Mondragon (mikemondragon@gmail.com)
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

    extend Base62

    def before_create
      self.token = unique_token
    end

    def before_destroy
      raise ActiveRecord::RecordNotFound.new("'it' token cannot be destroyed!") if 
        base62_encode(self.key) == 'it'
    end

    ##
    # The maximum power of the base 62 keys

    MAX_POW = 5 # 62 ** 5 == 916M or almost 1B

    ##
    # Recycle the keys from urls base in options cirteria.  options[:id] to
    # options[:id] recycle a specific User.find(options[:id]).
    # options[:conditions] to pass in custom :conditions.
    # Else options[:days_ago] or empty and defaults to 30 and 
    # options[:hits] or empty and defaults to 1
    # to recycle dangling urls by

    def self.recycle(options = {})
      recycled = 0
      if options[:id].is_a? Fixnum
        recycle_url find(options[:id])
        recycled = 1
      elsif options[:conditions]
        find(:all, :order => "id desc",
             :conditions => options[:conditions]
        ).each_with_index do |u,i|
          recycle_url u
          recycled = i+1
        end
      elsif options[:keys]
        options[:keys].split(',').each_with_index do |key,i|
        u = find(:first, :conditions => {:key => key})
        next unless u
          recycle_url u
          recycled += 1
        end
      else
        days_ago = options[:days_ago].to_i rescue 30
        days_ago = 30 if days_ago < 1
        days_ago = Time.now.ago(days_ago.days).to_s(:db)
        hits = options[:hits].to_i || 1

        find(:all, :order => "id desc",
             :conditions => ["hits <= ? and created_at <= ?", hits, days_ago]
        ).each_with_index do |u,i|
          recycle_url u
          recycled = i+1
        end

        days_ago = options[:days_ago].to_i rescue 60
        days_ago = 60 if days_ago < 1
        days_ago = Time.now.ago(days_ago.days).to_s(:db)
        find(:all, :order => "id desc",
             :conditions => ["updated_at <= ?", days_ago]
        ).each_with_index do |u,i|
          recycle_url u
          recycled = i+1
        end
      end
      recycled
    end

    ##
    # look up the URL for the base62 token

    def self.get(token)
      # do some basic error checking
      return nil unless base62_validate(token)
      key = base62_decode(token)
      # handle production mysql on the key column
      conditions = Hurl::HENV == :production ? "\`key\` = ?" : "key = ?"
      url = self.find(:first, :conditions => [conditions, key])
      return nil if url.nil? 

      url.increment(:hits)
      url.save # don't die if we can't increment
      url.url
    end

    private

    def unique_token
      count = self.count
      # determine the maximum key size based on the current number of Urls
      pow = (1..MAX_POW).detect{|i| count < (62**i)/2}
      key = 0
      (1..10).detect do |i| 
        key = rand(62**pow)
        Url.find_by_key(key) ? nil : key
      end
    end
  end

  ##
  # Camping migration to create our database

  class CreateTheTable < V 0.1

    def self.up
      create_table :hurl_urls, :force => true do |t|
        t.column :key,         :integer, :null => false
        t.column :url,         :string,  :null => false
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

