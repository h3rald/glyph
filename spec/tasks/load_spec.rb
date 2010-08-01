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

	it "[snippets] should not load snippets.xml in Lite mode" do
		Glyph.lite_mode = true
		lambda { Glyph.run! 'load:snippets'}.should_not raise_error
		Glyph::SNIPPETS[:test].blank?.should == true
		Glyph.lite_mode = false
	end

	it "[macros] should load macro definitions" do
		lambda { Glyph.run! 'load:macros'}.should_not raise_error
		Glyph::MACROS[:note].blank?.should == false
		Glyph::MACROS[:"#"].blank?.should == false
	end

	it "[macros] should be able to load only core macros" do
		language 'core'
		output_for("$:[language.set|glyph]").blank?.should == true
		Glyph['language.set'].should == 'glyph'
	end
	
	it "[macros] should be able to load only filter macros" do
		language 'filters'
		output_for("textile[*test*]").should == "<p><strong>test</strong></p>"
	end

	it "[config] should load configuration files and apply overrides" do
    Glyph.config_refresh
		lambda { Glyph.run! 'load:config'}.should_not raise_error
		Glyph['system.quiet'] = true
		Glyph::PROJECT_CONFIG.blank?.should == false
		Glyph::SYSTEM_CONFIG.blank?.should == false
		Glyph['system.structure.headers'].class.to_s.should == "Array"
	end

	it "[macros] should load HTML macros as well when generating web output" do
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:macros'
		Glyph::MACROS[:section].blank?.should == false
	end

	it "[layouts] should load layouts" do
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:macros'
		Glyph::MACROS[:"layout:topic"].blank?.should == false
	end

end
