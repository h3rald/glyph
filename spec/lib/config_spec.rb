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
		lambda { @cfg.read }.should raise_error
		@write_config_file.call @valid
		@cfg.read.should == {:test => true}
	end

	it "should get and set configuration data through dot notation" do
		@write_config_file.call @valid
		@cfg.read
		lambda { @cfg.set :test, false }.should_not raise_error
		lambda { @cfg.set "test.wrong", true}.should raise_error
		lambda { @cfg.set "test2.value", true}.should_not raise_error
		@cfg.get("test2.value").should == true
		lambda { @cfg.set "test2.value", "false"}.should_not raise_error
		@cfg.get("test2.value").should == false
		@cfg.get("test2.value2").should == nil
		@cfg.to_hash.should == {:test => false, :test2 => {:value => false}}
	end

	it "can be resetted with a Hash, if resettable" do
		lambda { @cfg.reset }.should raise_error
		cfg2 = Glyph::Config.new :resettable => true
		cfg2.reset :test => "reset!"
		cfg2.to_hash.should == {:test => "reset!"}	
	end

	it "should be set to an empty Hash by default" do
		cfg2 = Glyph::Config.new
		cfg2.to_hash.should == {}
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
		cfg2.to_hash.should == @cfg.to_hash
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
		@cfg.to_hash.should == updated
		hash1.merge! hash2
		hash1.should == {:a =>1, :b => {:b1 => 1111, :b2 => 2222, :b3 => {:b12 =>2222}}, :c=> 3}
	end


end
