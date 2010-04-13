#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "load" do

	before do
		delete_project
		create_project
	end

	after do
		delete_project
	end

	it "should raise an error unless PROJECT is a valid project directory" do
		delete_project
		lambda { Glyph.run! 'load:all' }.should raise_error
	end
	
	it "[snippets] should load snippet definitions" do
		lambda { Glyph.run! 'load:snippets'}.should_not raise_error
		Glyph::SNIPPETS[:test].blank?.should == false
	end

	it "[snippets] should not load snippets.xml in Lite mode"

	it "[macros] should load macro definitions" do
		lambda { Glyph.run! 'load:macros'}.should_not raise_error
		Glyph::MACROS[:note].blank?.should == false
		Glyph::MACROS[:"#"].blank?.should == false
	end

	it "[config] should load configuration files and apply overrides" do
		Glyph::PROJECT_CONFIG.blank?.should == false
		Glyph::SYSTEM_CONFIG.blank?.should == false
		cfg('structure.headers').class.to_s.should == "Array"
	end

end
