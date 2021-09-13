source 'https://rubygems.org'
ruby '2.7.2'

###
### Depending on the environment we have to make a few adjustments to our dependencies
### since we'll want to have Sidekiq Pro (Licensing matters!) and a few other
### capabilities which are held back for the hosted service (at least for some time)
###
if ENV["APP_ENV"] == "production-engine"

  ### Sidekiq Pro
  source "https://gems.contribsys.com/" do
    gem 'sidekiq-pro'
  end

  # Capabilities only available to hosted service for now
  # prod gems
  source 'https://gem.fury.io/intrigueio/' do
    gem 'intrigue-ident-private'
    gem 'intrigue-core-private'
    gem 'ruclei'
  end

  # prod ident
  gem 'intrigue-ident', :git => 'https://github.com/intrigueio/intrigue-ident.git', :branch => "main"

elsif ENV["APP_ENV"] == "development-engine"

  # enable regular sidekiq, and link to local gems
  gem 'sidekiq'

  ###
  ### Handy for local dev, just here to make it easy/obvious where to put these
  ###
  gem 'intrigue-ident',                :path => "~/intrigue/ident"
  gem 'intrigue-ident-private',        :path => "~/intrigue/ident-private"
  gem 'intrigue-core-private',         :path => "~/intrigue/core-private"
  gem 'ruclei',                        :path => "~/intrigue/ruclei"

else # every other environment, including production-oss

  # no sidekiq pro, so fall back to oss sidekiq
  gem 'sidekiq'

  # prod gems
  gem 'intrigue-ident',         :git => 'https://github.com/intrigueio/intrigue-ident.git', :branch => "main"

end

gem 'sidekiq-failures'        # Background Tasks
gem 'sidekiq-limit_fetch'     # Dynamic queueing

# core
gem 'sinatra'                 #'~> 2.0.1'
gem 'sinatra-contrib'         #'~> 2.0.1'
gem 'puma'                    # Application Server
gem 'eventmachine'
gem 'rack-cors'
gem 'redis'                   # Redis
gem 'redis-namespace'         # Redis
gem 'thor'                    # CLI
gem 'elasticsearch'           # Database
gem 'faraday_middleware-aws-sigv4' # AWS elasticsearch
gem 'iconv'                   # Encoding
gem 'rest-client'             # Web hooks, some tasks
gem 'rack-protection'         # https://github.com/sinatra/rack-protection
gem 'intrigue_api_client',    :path => "api_client"
gem 'yajl-ruby'
gem 'nokogiri'                # Client::Search::*Scraper
gem 'compare-xml'

# Database
gem 'sequel'
gem 'sqlite3'
gem 'pg'

# Async DNS
gem 'async-dns'

# Tasks
gem 'aws-sdk-ecs'
gem 'aws-sdk-ec2'
gem 'aws-sdk-iam'
gem 'aws-sdk-route53'
gem 'aws-sdk-s3'
gem 'aws-sdk-sqs'
gem 'json', '>= 2.3.0'
gem 'censys',                 :git => 'https://github.com/pentestify/censys.git'
gem 'cloudflare',             :git => 'https://github.com/intrigueio/cloudflare.git'
gem 'dnsimple'
gem 'dnsruby'                 # dns_zone_transfer
gem 'flareon'                 # dns resolution over http
gem 'google-api-client'
gem 'googleauth'
gem 'google-cloud-storage'
gem 'googleajax'              # search_google
gem 'google_search_results'
gem 'ip_ranger',              :git => "https://github.com/intrigueio/ip_ranger"
gem 'ipaddr'
gem 'net-dns'                 # dns_cache_snoop
gem 'net-http2'
gem 'http-2'                  # http2 client support
gem 'neutrino_api',           :git => 'https://github.com/intrigueio/NeutrinoAPI-Ruby.git'
gem 'opencorporates',         :git => 'https://github.com/pentestify/opencorporates.git'
gem 'openssl'
gem 'rex'
gem 'rex-sslscan',            :git => 'https://github.com/intrigueio/rex-sslscan.git'
gem 'ruby-nmap',              :git => 'https://github.com/pentestify/ruby-nmap.git'
gem 'rubyzip'
gem 'ruby_smb'
gem 'shodan'                  # search_shodan
gem 'snmp',                   :git => 'https://github.com/intrigueio/ruby-snmp.git'
gem 'spidr',                  :git => 'https://github.com/intrigueio/spidr.git'
gem 'towerdata_api'           # search_towerdata
gem 'whois'                   # dns_zone_transfer, whois
gem 'whois-parser'            # whois
gem 'whoisology',             :git => 'https://github.com/pentestify/whoisology.git'
gem 'octokit', '~> 4.0'
gem 'open3'
gem 'typhoeus'
gem 'zetalytics'

# vulndb
gem 'versionomy'

# comment if developing on chrome_remote locally
gem 'chrome_remote',          :git => 'https://github.com/intrigueio/chrome_remote.git'

# Handlers
gem 'couchrest'
gem 'fog-aws'

# production process management
gem 'god'

# Error tracking (disabled by default)
gem "sentry-ruby"
gem "sentry-sidekiq"

# Development
group :development, :test do
  gem 'gem-licenses'
  gem 'foreman'
  gem 'pry'                     # Debugging
  gem 'pry-byebug'              # Debugging
  gem 'yard'
  gem 'rake'                    # Testing
  gem 'rspec'                   # Testing
  gem 'rack-test'               # Testing
end
