#!/usr/bin/env ruby

require_relative '../core'
require 'pry'

###
### Define the prompt & drop into pry repl
###
Pry.start(self, :prompt => [proc{"intrigue>"}])
