####
### These ruby-core libs should always be availble 
###
require 'base64'
require 'date'
require 'digest'
require 'ident'
require 'json'
require 'net/http'
require 'resolv'
require 'socket'
require 'tempfile'
require 'thread'
require 'uri'
require 'webrick'


###
### SYSTEM HELPERS (for use everywhere)
###

# Intrigue System-wide Bootstrap
require_relative 'system/bootstrap'
include Intrigue::Core::System::Bootstrap

# Intrigue System-wide Match Exeptions
require_relative 'system/match_exceptions'
include Intrigue::Core::System::MatchExceptions

# Intrigue System-wide Validations 
require_relative 'system/validations'
include Intrigue::Core::System::Validations

# Intrigue System-wide Helpers (both app and backend) 
require_relative 'system/helpers'
include Intrigue::Core::System::Helpers

# Intrigue System-wide Helpers (both app and backend) 
require_relative 'system/dns_helpers'
include Intrigue::Core::System::DnsHelpers

# Intrigue Export Format
require_relative 'system/json_data_export_file'
###
### END SYSTEM HELPERS
###

require_relative 'task_factory'
require_relative 'issue_factory'
require_relative 'issues/base'

## Mixin task helper functionality ... these are now part of the common base
## since checks now have 'tasks' in them, and inheirt from base task
## 
require_relative 'tasks/helpers/generic'
require_relative 'tasks/helpers/web'
tasks_folder = File.expand_path('../tasks/helpers', __FILE__) 
Dir["#{tasks_folder}/*.rb"].each { |file| require_relative file }

# now we can require base task and everyting that inherits it
require_relative 'tasks/base'
require_relative 'checks/base'
