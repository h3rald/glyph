#!/usr/bin/env ruby
# Glyph
#
# @website http://www.h3rald.com/glyph
# @author Fabio Cevasco (mailto:h3rald@h3rald.com)
# @copyright Copyright (c) 2009 Fabio Cevasco
# @license BSD

require 'rubygems'
require 'pathname'
require 'yaml'
require 'gli'
require 'extlib'
require 'rake'

module Glyph

	# Glyph's main configuration hash
	CONFIG = {}

	# Library directory
	LIB_DIR = Pathname(__FILE__).dirname.expand_path/'glyph'

	# Spec directory
	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'

	# Tasks directory
	TASKS_DIR = Pathname(__FILE__).dirname.expand_path/'../tasks'

	# Default rake app
	APP = Rake.application


	require LIB_DIR/'system_extensions'
	require LIB_DIR/'commands'

	def self.cfg(setting)
		case
		when setting.respond_to?(:pair?) && setting.pair? then
			CONFIG[setting.name] = setting.value
		when setting.is_a?(Symbol) then
			CONFIG[setting]
		else
			raise ArgumentError, "Pair or Symbol expected"
		end
	end

	def self.setup
		# Setup rake app
		FileList["#{TASKS_DIR}/**/*.rake"].each do |f|
			load f
		end	
	end

	def self.enable(task)
		Rake::Task[task].reenable
	end

	def self.run!(task, *args)
		Rake::Task[task].reenable
		self.run task, *args
	end

	def self.run(task, *args)
		Rake::Task[task].invoke *args
	end

end

Glyph.setup
