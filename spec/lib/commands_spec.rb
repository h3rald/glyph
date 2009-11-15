#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "glyph" do

	it "[init] should create a project in the current directory" do
		Glyph.enable "project:create"
		create_project_dir
		run_command(['init']).match(/error:/m).should_not == nil
		Dir.chdir @project.to_s
		run_command(['init']).match(/error:/m).should == nil
		delete_project_dir
	end

	it "[config] should read configuration settings" do
		run_command(["config", "-g"]).match(/error/).should_not == nil
		Glyph.config_override :quiet, false
		run_command(["config", "quiet"]).match(/false/m).should_not == nil
		Glyph.config_override :quiet, true
	end

	it "[config] should write configuration settings" do
		run_command(["config", "test_setting", true]).match(/error/).should == nil
		Glyph::CONFIG.get(:test_setting).should == true
		Glyph::PROJECT_CONFIG.get('test_setting').should == true
		Glyph::GLOBAL_CONFIG.get('test_setting').should_not == true
		run_command(["config", "-g", "another.test", "something else"]).match(/error/).should == nil
		Glyph::CONFIG.get("another.test").should == "something else"
		Glyph::PROJECT_CONFIG.get('another.test').should_not == "something else"
		Glyph::GLOBAL_CONFIG.get('another.test').should == "something else"
		run_command(["config", "-g", "yet.another.test", "something else", "extra argument"]).match(/error/).should_not == nil
	end


end
