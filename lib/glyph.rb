#!/usr/bin/env ruby
# Glyph
#
# @website http://www.h3rald.com/glyph
# @author Fabio Cevasco (mailto:h3rald@h3rald.com)
# @copyright Copyright (c) 2009-2010 Fabio Cevasco
# @license BSD

require 'rubygems'
require 'pathname'
require 'yaml'
require 'gli'
require 'extlib'
require 'treetop'
require 'rake'

module Glyph

	# Program Version
	VERSION = '0.1.0'

	# Library directory
	LIB = Pathname(__FILE__).dirname.expand_path/'glyph'
	
	# Glyph home directory
	HOME = LIB/'../../'

	# Spec directory
	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'

	# Tasks directory
	TASKS_DIR = Pathname(__FILE__).dirname.expand_path/'../tasks'

	# Default rake app
	APP = Rake.application

	# Snippets hash
	SNIPPETS = {}

	# Macros hash
	MACROS = {}

	# IDs array
	IDS = []

	require LIB/'system_extensions'
	require LIB/'config'
	require LIB/'glyph_language'
	require LIB/'preprocessor_actions'
	require LIB/'preprocessor'

	def self.testing?
		const_defined? :TEST_MODE rescue false
	end

	# Current project directory
	PROJECT = (Glyph.testing?) ? Glyph::SPEC_DIR/"test_project" : Pathname.new(Dir.pwd)

	# Glyph configuration
	CONFIG = Glyph::Config.new :resettable => true, :mutable => false

	home_dir = Pathname.new(RUBY_PLATFORM.match(/win32|mingw/) ? ENV['HOMEPATH'] : ENV['HOME'])
	SYSTEM_CONFIG = Glyph::Config.new(:file => HOME/'config.yml')
	GLOBAL_CONFIG = Glyph.testing? ? Glyph::Config.new(:file => SPEC_DIR/'.glyphrc') : Glyph::Config.new(:file => home_dir/'.glyphrc')
	PROJECT_CONFIG = Glyph::Config.new(:file => PROJECT/'config.yml')

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
