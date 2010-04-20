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

# Glyph is a Rapid Document Authoring Framework able to produce structured documents 	effortlessly.
module Glyph

	LIB = Pathname(__FILE__).dirname.expand_path/'glyph'

	HOME = LIB/'../../'

	require LIB/'system_extensions'
	require LIB/'config'
	require LIB/'node'
	require LIB/'document'
	require LIB/'glyph_language'
	require LIB/'macro_validators'
	require LIB/'macro'
	require LIB/'interpreter'

	VERSION = file_load(HOME/'VERSION').strip

	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'

	TASKS_DIR = Pathname(__FILE__).dirname.expand_path/'../tasks'

	APP = Rake.application

	SNIPPETS = {}

	MACROS = {}

	@@document = nil
	@@lite_mode = false
	@@debug_mode = false

	# Returns true if Glyph is running in test mode
	def self.testing?
		const_defined? :TEST_MODE rescue false
	end
	
	# Returns true if Glyph is running in debug mode
	def self.debug?
		@@debug_mode
	end

	def self.debug_mode=(mode)
		@@debug_mode = mode
	end

	def self.lite_mode=(mode)
		@@lite_mode = mode
	end
	
	# Returns true if Glyph is running in "lite" mode
	def self.lite?
		@@lite_mode
	end

	PROJECT = (Glyph.testing?) ? Glyph::SPEC_DIR/"test_project" : Pathname.new(Dir.pwd)

	CONFIG = Glyph::Config.new :resettable => true, :mutable => false

	home_dir = Pathname.new(RUBY_PLATFORM.match(/win32|mingw/) ? ENV['HOMEPATH'] : ENV['HOME'])
	SYSTEM_CONFIG = 
		Glyph::Config.new(:file => HOME/'config.yml')
	GLOBAL_CONFIG = 
		Glyph.testing? ? Glyph::Config.new(:file => SPEC_DIR/'.glyphrc') : Glyph::Config.new(:file => home_dir/'.glyphrc')
	PROJECT_CONFIG = 
		Glyph::Config.new(:file => PROJECT/'config.yml', :resettable => true) rescue Glyph::Config.new(:resettable => true, :mutable => true)

	# Loads all Rake tasks
	def self.setup
		FileList["#{TASKS_DIR}/**/*.rake"].each do |f|
			load f
		end	
	end

	def self.document
		@@document
	end
	
	def self.document=(document)
		@@document = document
	end
	
	# Returns the value of a configuration setting
	def self.[](setting)
		Glyph::CONFIG.get(setting)
	end

	# Overrides a configuration setting
	# @param setting [String, Symbol] the configuration setting to change
	# @param value the new value
	def self.[]=(setting, value)
		PROJECT_CONFIG.set setting, value
		self.config_refresh
	end

	# Restores Glyph configuration (keeping all overrides and project settings)
	def self.config_refresh
		CONFIG.merge!(SYSTEM_CONFIG.merge(GLOBAL_CONFIG.merge(PROJECT_CONFIG)))
	end

	# Resets Glyph configuration (removing all overrides and project settings)
	def self.config_reset
		Glyph::CONFIG.reset
		Glyph::PROJECT_CONFIG.reset
		self.config_refresh
	end

	# Returns true if the PROJECT constant is set to a valid Glyph project directory
	def self.project?
		children = ["styles", "text", "output", "snippets.yml", "config.yml", "document.glyph"].sort
		actual_children = PROJECT.children.map{|c| c.basename.to_s}.sort 
		(actual_children & children) == children
	end

	def self.reset
		self.enable_all
		self.config_reset
		MACROS.clear
		SNIPPETS.clear
	end


	def self.enable_all
		Rake::Task.tasks.each {|t| t.reenable }
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
		MACROS[name.to_sym] = block
	end

	# Defines an alias for an existing macro
	# @param [Hash] pair the single-key hash defining the alias
	# @example
	# 	{:old_name => :new_name}
	def self.macro_alias(pair)
		name = pair.keys[0].to_sym
		found = MACROS[name]
		if found then
			self.warning "Invalid alias: macro '#{name}' already exists."
			return
		end
		MACROS[name] = MACROS[pair.values[0].to_sym]
	end

	def self.compile(src, out=nil)
		dir = Pathname.new(src).parent
		Dir.chdir dir.to_s	
		GLI.run ["compile", src, out].compact	
		self.lite_mode = false
	end

	def self.filter(text)
		self.lite_mode = true
		self.enable_all
		Glyph.run 'load:all'
		result = ""
		begin
			result = Interpreter.new(text).document.output
		rescue Exception => e
			raise if self.debug?
		ensure
			self.lite_mode = false
		end
		result
	end
	
	# Prints a message
	# @param [#to_s] message the message to print
	def self.info(message)
		puts "#{message}" unless Glyph[:quiet]
	end

	# Prints a warning
	# @param [#to_s] message the message to print
	def self.warning(message)
		puts "warning: #{message}" unless Glyph[:quiet]
	end

	def self.error(message)
		puts "error: #{message}" unless Glyph[:quiet]
	end
	
end

Glyph.setup
