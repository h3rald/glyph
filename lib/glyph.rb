#!/usr/bin/env ruby
# Copyright (c) 2009-2010 Fabio Cevasco
# website: http://www.h3rald.com/glyph
# license: BSD

require 'rubygems'
require 'pathname'
require 'yaml'
require 'gli'
require 'extlib'
require 'treetop'
require 'rake'

# Glyph is a Rapid Document Authoring Framework
module Glyph

	VERSION = '0.1.0'

	LIB = Pathname(__FILE__).dirname.expand_path/'glyph'

	HOME = LIB/'../../'

	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'

	TASKS_DIR = Pathname(__FILE__).dirname.expand_path/'../tasks'

	APP = Rake.application

	SNIPPETS = {}

	MACROS = {}

	TODOS = []

	ERRORS = []

	require LIB/'system_extensions'
	require LIB/'config'
	require LIB/'node'
	require LIB/'document'
	require LIB/'glyph_language'
	require LIB/'macro'
	require LIB/'interpreter'

	# Returns true if Glyph is running in test mode
	def self.testing?
		const_defined? :TEST_MODE rescue false
	end

	PROJECT = (Glyph.testing?) ? Glyph::SPEC_DIR/"test_project" : Pathname.new(Dir.pwd)

	CONFIG = Glyph::Config.new :resettable => true, :mutable => false

	home_dir = Pathname.new(RUBY_PLATFORM.match(/win32|mingw/) ? ENV['HOMEPATH'] : ENV['HOME'])
	SYSTEM_CONFIG = Glyph::Config.new(:file => HOME/'config.yml')
	GLOBAL_CONFIG = Glyph.testing? ? Glyph::Config.new(:file => SPEC_DIR/'.glyphrc') : Glyph::Config.new(:file => home_dir/'.glyphrc')
	PROJECT_CONFIG = Glyph::Config.new(:file => PROJECT/'config.yml')

	# Loads all Rake tasks
	def self.setup
		FileList["#{TASKS_DIR}/**/*.rake"].each do |f|
			load f
		end	
	end

	# Overrides a configuration setting
	# @param setting [String, Symbol] the configuration setting to change
	# @param value the new value
	def self.config_override(setting, value)
		PROJECT_CONFIG.set setting, value
		reset_config
	end

	# Resets Glyph configuration
	def self.reset_config
		CONFIG.merge!(SYSTEM_CONFIG.merge(GLOBAL_CONFIG.merge(PROJECT_CONFIG)))
	end

	# Returns true if the PROJECT constant is set to a valid Glyph project directory
	def self.glyph_project?
		children = ["config", "text", "output"]
		PROJECT.children.map{|c| c.basename.to_s} & children == children
	end

	# Enables a Rake task
	# @param task the task to enable
	def self.enable(task)
		Rake::Task[task].reenable
	end

	# Reenables and runs a Rake task
	# @param task the task to enable
	# @param *args the task arguments
	def self.run!(task, *args)
		Rake::Task[task].reenable
		self.run task, *args
	end

	# Runs a Rake task
	# @param task the task to enable
	# @param *args the task arguments
	def self.run(task, *args)
		Rake::Task[task].invoke *args
	end

	# Defines a new macro
	# @param name [Symbol, String] the name of the macro
	def self.macro(name, &block)
		MACROS[name] = block
	end

	# Defines an alias for an existing macro
	# @example
	# 	{:old_name => :new_name}
	def self.macro_alias(pair)
		MACROS[pair.name.to_sym] = MACROS[pair.value.to_sym]
	end
	
end

Glyph.setup
