#!/usr/bin/env ruby

module Glyph

	class Config

		def initialize(options={})
			default_options = {:file => nil, :data => {}, :resettable => false, :mutable => true}
			@options = default_options.merge options
			@file = @options[:file]
			@data = @options[:data]
			read if @file
		end

		def to_hash
			@data
		end

		def reset(hash={})
			raise RuntimeError, "Configuration cannot be reset" unless @options[:resettable]
			raise RuntimeError, "Configuration data is not stored in a Hash" unless hash.is_a? Hash
			@data = hash
		end

		def merge_or_update(cfg, method=:merge)
			raise ArgumentError, "#{cfg} is not a Glyph::Config" unless cfg.is_a? Glyph::Config
			block = lambda do |key, v1, v2|
				if v1.is_a?(Hash) && v2.is_a?(Hash) then
					v1.send(method, v2, &block)
				else
					v2
				end
			end
			new_data = @data.send(method, cfg.to_hash, &block)
			opts = @options.merge :data => new_data, :file => nil
			(method == :merge) ? Config.new(opts) : self
		end

		def update(cfg)
			merge_or_update cfg, :update
		end

		def merge(cfg)
			merge_or_update cfg, :merge
		end

		alias merge! update

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

		def set(setting, value)
			raise RuntimeError, "Configuration cannot be changed" unless @options[:mutable]
			if value.is_a?(String) && value.match(/^(:.+|\[.*\]|\{.*\}|true|false|nil)$/) then
				value = Kernel.instance_eval value
			end
			hash = @data
			path = setting.to_s.split(".").map{|s| s.intern}
			count = 1
			path.each do |s|
				if hash.has_key? s then
					if count == path.length then # destination
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
		end

		def get(expr)
			@data.instance_eval "self#{expr.to_s.split(".").map{|key| "[:#{key}]" }.join}" rescue nil
		end

		def write
			raise RuntimeError, "Configuration is not stored in a file." if @file.blank?
			yaml_dump @file, @data
		end

	end

end
