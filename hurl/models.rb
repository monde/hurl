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

    ##
    # The maximum width of our keys

    MAX_KEY_WIDTH = 5 # 62 ** 5 == 916M or almost 1B

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
    # Does the mechanics of recycling a +Url+

    def self.recycle_url(url)
      return if url.key == 'it'
      url.destroy
    end

    ##
    # look up the URL for the base62 key

    def self.get(key)
      # do some basic error checking
      return nil unless base62_validate(key)
      # handle production mysql on the key column
      conditions = Hurl::HENV == :production ? "\`key\` = ?" : "key = ?"
      url = self.find(:first, :conditions => [conditions, key])
      return nil if url.nil? 

      url.increment(:hits)
      url.save # don't die if we can't increment
      url.url
    end
  end

  ##
  # Camping migration to create our database

  class CreateTheTable < V 0.1
    extend Base62
    def self.up

      case Hurl::HENV
      when :production
        # coupled to MySQL MyISAM for performance
        create_table :hurl_urls, :options => 'engine=MyISAM', :force => true do |t|
          # make varchar care about case sensitivity
          t.columns << "\`key\` varchar(#{Url::MAX_KEY_WIDTH}) BINARY NOT NULL"
        end
        add_column :hurl_urls, :url,         :string, :limit => 255, :null => false
        add_column :hurl_urls, :hits,        :integer, :default => 0
        add_column :hurl_urls, :created_at,  :datetime
        add_column :hurl_urls, :updated_at,  :datetime
      else
        # sqlite3 friendly
        create_table :hurl_urls, :force => true do |t|
          t.column :key,         :string, :limit => Url::MAX_KEY_WIDTH, :null => false
          t.column :url,         :string, :limit => 255, :null => false
          t.column :hits,        :integer, :default => 0
          t.column :created_at,  :datetime
          t.column :updated_at,  :datetime
        end
      end
      add_index :hurl_urls, :key, :unique => true
    end

    def self.down
      remove_index :hurl_urls, :key
      drop_table :hurl_urls
    end

  end

end

