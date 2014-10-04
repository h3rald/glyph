#!/usr/bin/env ruby
# encoding: utf-8

describe Glyph::Config do

	before do 
		@valid = {:test => true}.to_yaml
		@invalid = [1,2,3].to_yaml
		@config_path = Glyph::SPEC_DIR/'config.yml'
		@write_config_file = lambda do |contents|
			File.open(@config_path, "w+") { |f| f.write(contents) }
		end
		@cfg = Glyph::Config.new :file => @config_path
	end

	after(:all) do
		@config_path.delete rescue nil
	end

	it "should load a YAML configuration file" do
		@write_config_file.call @invalid
		expect { @cfg.read }.to raise_error
		@write_config_file.call @valid
		expect(@cfg.read).to eq({:test => true})
	end

	it "should get and set configuration data through dot notation" do
		@write_config_file.call @valid
		@cfg.read
		expect { @cfg.set :test, false }.not_to raise_error
		expect { @cfg.set "test.wrong", true}.to raise_error
		expect { @cfg.set "test2.value", true}.not_to raise_error
		expect(@cfg.get("test2.value")).to eq(true)
		expect { @cfg.set "test2.value", "false"}.not_to raise_error
		expect(@cfg.get("test2.value")).to eq(false)
		expect(@cfg.get("test2.value2")).to eq(nil)
		expect(@cfg.to_hash).to eq({:test => false, :test2 => {:value => false}})
	end

	it "can be resetted with a Hash, if resettable" do
		expect { @cfg.reset }.to raise_error
		cfg2 = Glyph::Config.new :resettable => true
		cfg2.reset :test => "reset!"
		expect(cfg2.to_hash).to eq({:test => "reset!"})	
	end

	it "should be set to an empty Hash by default" do
		cfg2 = Glyph::Config.new
		expect(cfg2.to_hash).to eq({})
	end

	it "should write a YAML configuration file" do
		@write_config_file.call @valid
		@cfg.read
		@cfg.set :test1, 1
		@cfg.set :test2, 2
		@cfg.set :test3, 3
		@cfg.write
		cfg2 = Glyph::Config.new :file => @config_path
		cfg2.read
		expect(cfg2.to_hash).to eq(@cfg.to_hash)
	end

	it "should merge with another Config without data loss" do
		hash1 = {:a =>1, :b => {:b1 => 1, :b2 => 2, :b3 => {:b11 => 1, :b12 =>2}, :b4 => 4}, :c => 3}
		hash2 = {:a =>1, :b => {:b1 => 1111, :b2 => 2222, :b3 => {:b12 =>2222}}}
		@write_config_file.call hash1.to_yaml
		@cfg.read
		@write_config_file.call hash2.to_yaml
		cfg2 = Glyph::Config.new :file => @config_path
		@cfg.update cfg2
		updated = {:a =>1, :b => {:b1 => 1111, :b2 => 2222, :b3 => {:b11 => 1, :b12 =>2222}, :b4 => 4}, :c=> 3}
		expect(@cfg.to_hash).to eq(updated)
		hash1.merge! hash2
		expect(hash1).to eq({:a =>1, :b => {:b1 => 1111, :b2 => 2222, :b3 => {:b12 =>2222}}, :c=> 3})
	end


end
