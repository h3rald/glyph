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

	# Current project directory
	PROJECT = Pathname.new(Dir.pwd)

	# Library directory
	LIB_DIR = Pathname(__FILE__).dirname.expand_path/'glyph'
	
	# Glyph home directory
	HOME = LIB_DIR/'../../'

	# Spec directory
	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'

	# Tasks directory
	TASKS_DIR = Pathname(__FILE__).dirname.expand_path/'../tasks'

	# Default rake app
	APP = Rake.application

	require LIB_DIR/'system_extensions'
	require LIB_DIR/'commands'
	require LIB_DIR/'config'

	def self.testing?
		const_defined? :TEST_PROJECT rescue false
	end

	# Glyph configuration
	CONFIG = Glyph::Config.new :resettable => true, :mutable => false

	home_dir = Pathname.new(RUBY_PLATFORM.match(/win32|mingw/) ? ENV['HOMEPATH'] : ENV['HOME'])
	SYSTEM_CONFIG = Glyph::Config.new(:file => HOME/'config.yml')
	GLOBAL_CONFIG = Glyph.testing? ? Glyph::Config.new(:file => SPEC_DIR/'.glyphrc') : Glyph::Config.new(:file => home_dir/'.glyphrc')
	PROJECT_CONFIG = Glyph.testing? ? Glyph::CONFIG.new(:file => TEST_PROJECT/'config/config.yml') : Glyph::Config.new(:file => PROJECT/'config.yml')

	def self.setup
		# Setup rake app
		FileList["#{TASKS_DIR}/**/*.rake"].each do |f|
			load f
		end	
		# Load configuration
		reset_config
	end

	def self.config_override(setting, value)
		PROJECT_CONFIG.set setting, value
		reset_config
	end

	def self.reset_config
		CONFIG.reset SYSTEM_CONFIG.to_hash.merge(GLOBAL_CONFIG.to_hash).merge(PROJECT_CONFIG.to_hash)
	end

	def self.glyph_project?
		children = ["config", "source", "output"]
		PROJECT.children.map{|c| c.basename.to_s} & children == children
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
