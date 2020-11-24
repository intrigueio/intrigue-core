#!/usr/bin/env ruby

require_relative '../core'
require 'pry'

alias _log puts
alias _log_good puts
alias _log_error puts
alias _log_debug puts

###
### Define the prompt & drop into pry repl
###
Pry.start(self, :prompt => [proc{"core>"}])
