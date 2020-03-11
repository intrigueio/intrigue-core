source 'https://rubygems.org'
ruby '2.6.5'

# core
gem 'sinatra',         '~> 2.0.1'
gem 'sinatra-contrib', '~> 2.0.1'
gem 'puma'                    # Application Server
gem 'eventmachine'

gem 'redis'                   # Redis
gem 'redis-namespace'         # Redis
gem 'sidekiq'                 # Background Tasks
gem 'sidekiq-failures'        # Background Tasks
gem 'sidekiq-limit_fetch'     # Dynamic queueing

gem 'thor'                    # CLI
gem 'elasticsearch'           # Database
gem 'iconv'                   # Encoding
gem 'rest-client'             # Web hooks, some tasks
gem 'rack-protection'         # https://github.com/sinatra/rack-protection
gem 'intrigue_api_client',    :path => "api_client"
gem 'yajl-ruby'
gem 'nokogiri'                # Client::Search::*Scraper
gem 'compare-xml'

# Testing
gem 'rake'                    # Testing
gem 'rspec'                   # Testing
gem 'rack-test'               # Testing

# Database
gem 'sequel'
gem 'sqlite3'
gem 'pg'

# Tasks
gem 'aws-sdk-sqs'             #,        '~> 3'
gem 'aws-sdk-s3'              #,         '~> 3'
gem 'aws-sdk-route53'
gem 'censys',                 :git => 'https://github.com/pentestify/censys.git'
gem 'cloudflare',             :git => 'https://github.com/intrigueio/cloudflare.git'
gem 'dnsbl-client',           :git => 'https://github.com/AnasBensalah/dnsbl-client.git'
gem 'dnsimple'
gem 'dnsruby'                 # dns_zone_transfer
gem 'em-resolv-replace'       # dns_brute_sub
gem 'flareon'                 # dns resolution over http
gem 'google-api-client'
gem 'googleauth'
gem 'google-cloud-storage'
gem 'googleajax'              # search_google
gem 'maxminddb',              :git => "https://github.com/intrigueio/maxminddb"
gem 'net-dns'                 # dns_cache_snoop
gem 'net-http2'               # http2 client support
gem 'neutrino_api',           :git => 'https://github.com/NeutrinoAPI/NeutrinoAPI-Ruby.git'
gem 'opencorporates',         :git => 'https://github.com/pentestify/opencorporates.git'
gem 'recog-intrigue',         :git => 'https://github.com/intrigueio/recog.git'
gem 'rex'
gem 'rex-sslscan',            :git => 'https://github.com/intrigueio/rex-sslscan.git'
gem 'ruby-nmap',              :git => 'https://github.com/pentestify/ruby-nmap.git'
gem 'rubyzip'
gem 'shodan'                  # search_shodan
gem 'snmp',                   :git => 'https://github.com/intrigueio/ruby-snmp.git'
gem 'spidr',                  :git => 'https://github.com/intrigueio/spidr.git'
gem 'towerdata_api'           # search_towerdata
gem 'whois'                   # dns_zone_transfer, whois
gem 'whois-parser'            # whois
gem 'whoisology',             :git => 'https://github.com/pentestify/whoisology.git'


# swap these if developing on chrome_remote locally
gem 'chrome_remote',          :git => 'https://github.com/intrigueio/chrome_remote.git'
#gem 'chrome_remote',          :path => "~/chrome_remote"

# swap these if developing on ident locally
gem 'intrigue-ident',         :git => 'https://github.com/intrigueio/intrigue-ident.git'
#gem 'intrigue-ident',         :path => "~/ident"

# vulndb
gem 'versionomy'

# Handlers
gem 'couchrest'
gem 'fog-aws'

# production process management
gem 'god'

# Development
gem 'foreman'
gem 'pry'                     # Debugging
gem 'pry-byebug'              # Debugging
gem 'yard'
gem "sentry-raven"            # Error tracking (disabled by default)
