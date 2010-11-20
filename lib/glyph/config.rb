# encoding: utf-8

module Glyph

	# The Glyph::Config class is used (you don't say!) to store configuration data. Essentially it wraps a Hash of Hashes
	# and provides some useful methods to access keys and subkeys.
	class Config

		include Glyph::Utils

		# Initializes the configuration with a hash of options:
		# * :file (default: nil) - A YAML file to read data from
		# * :data (default: {})- The initial contents
		# * :resettable (default: false) - Whether the configuration can be reset (cleared) or not
		# * :mutable (default: true) - Whether the configuration can be changed or not
		#
		# @param [Hash] options the configuration options (merged with the the defaults)
		def initialize(options={})
			default_options = {:file => nil, :data => {}, :resettable => false, :mutable => true}
			@options = default_options.merge options
			@file = @options[:file]
			@data = @options[:data]
			read if @file
		end

		# Returns the underlying data hash
		# @return [Hash] Configuration data
		def to_hash
			@data
		end

		# Resets all configuration data
		# @param [Hash] hash the new configuration data to store
		# @raise [RuntimeError] unless the configuration is resettable or if no hash is passed
		# @return [Hash] Configuration data 
		def reset(hash={})
			raise RuntimeError, "Configuration cannot be reset" unless @options[:resettable]
			raise RuntimeError, "Configuration data is not stored in a Hash" unless hash.is_a? Hash
			@data = hash
		end

		# Updates configuration data by applying Hash#update to each sub-hash of data, recursively.
		# @param [Glyph::Config] cfg the configuration to update from
		# @raise [ArgumentError] unless cfg is a Glyph::Config
		# @return self
		def update(cfg)
			merge_or_update cfg, :update
		end

		# Merges configuration data by applying Hash#merge to each sub-hash of data, recursively.
		# @param [Glyph::Config] cfg the configuration to merge with
		# @raise [ArgumentError] unless cfg is a Glyph::Config
		# @return [Glyph::Config] a new merged configuration 
		def merge(cfg)
			merge_or_update cfg, :merge
		end

		alias merge! update

		# Reads the contents of a file and stores them as configuration data
		# @return [Hash] Configuration data
		# @raise [RuntimeError] if self is not linked to a file or if the file does not contain a serialized Hash
		def read
			raise RuntimeError, "Configuration is not stored in a file." if @file.blank?
			if @file.exist? then 
				contents = yaml_load @file
				raise RuntimeError, "Invalid configuration file '#{@file}'" unless contents.is_a? Hash
				@data = contents
			else
				@data = {}
			end
			@data
		end

		# Updates a configuration setting
		# @param [String, Symbol] setting the setting to update
		# @param [Object] value the value to store. Where applicable (Array, Hash, Boolean, Nil), attempts 
		# 	to evaluate string values
		# @return [Object] the new value
		# @raise [RuntimeError] unless the configuration is mutable
		# @raise [ArgumentError] if the setting refers to an invalid namespace
		# @example
		# 	cfg = Glyph::Config.new
		# 	cfg.set "system.quiet", true 								# Sets "system.quiet" => true
		# 	cfg.set "test.test_value", "[1,2,3]" # Sets :test => {:test_value => [1,2,3]}
		# 	cfg.set "system.quiet", "false" 							# Sets "system.quiet" => false
		def set(setting, value)
			raise RuntimeError, "Configuration cannot be changed" unless @options[:mutable]
			if value.is_a?(String) && value.match(/^(["'].*["']|:.+|\[.*\]|\{.*\}|true|false|nil)$/) then
				value = Kernel.instance_eval value
			end
			hash = @data
			path = setting.to_s.split(".").map{|s| s.intern}
			count = 1
			path.each do |s|
				if hash.has_key? s then
					if count == path.length then 
						# destination
						hash[s] = value
					else
						if hash[s].is_a?(Hash) then
							hash = hash[s]
							count +=1
						else
							raise ArgumentError, "Invalid namespace #{s}"
						end
					end
				else
					# key not found
					if count == path.length then # destination
						hash[s] = value
					else
						# create a new namespace
						hash[s] = {}
						hash = hash[s]
						count +=1
					end
				end
			end
			value
		end

		# Returns a configuration setting
		# @param [String, Symbol] setting the setting to retrieve
		# @return [Object] the new value
		# @see Glyph::Config#set
		# @example
		# 	cfg = Glyph::Config.new
		# 	cfg.get "system.quiet"							# true
		# 	cfg.get "test.test_value"	# [1,2,3]
		def get(setting)
			@data.instance_eval "self#{setting.to_s.split(".").map{|key| "[:#{key}]" }.join}" rescue nil
		end

		# Serialize configuration data and writes it to a file
		# @raise [RuntimeError] if the configuration is not linked to a file
		def write
			raise RuntimeError, "Configuration is not stored in a file." if @file.blank?
			yaml_dump @file, @data
		end

		private

		def merge_or_update(cfg, method=:merge)
			raise ArgumentError, "#{cfg} is not a Glyph::Config" unless cfg.is_a? Glyph::Config
			block = lambda do |key, v1, v2|
				(v1.is_a?(Hash) && v2.is_a?(Hash)) ? v1.send(method, v2, &block) :	v2
			end
			new_data = @data.send(method, cfg.to_hash, &block)
			opts = @options.merge :data => new_data, :file => nil
			(method == :merge) ? Config.new(opts) : self
		end

	end

end
