#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")
require 'glyph/commands'

describe "glyph" do

	before do
		create_project_dir
	end

	after do
		delete_project
	end

	it "[init] should create a project in the current directory" do
		Glyph.enable "project:create"
		run_command_successfully(['init']).should == false
		Dir.chdir Glyph::PROJECT.to_s
		run_command_successfully(['init']).should == true
	end

	it "[config] should read configuration settings" do
		create_project
		run_command_successfully(["config", "-g"]).should == false
		run_command(["config", "filters.target"]).match(/html/m).should_not == nil
	end

	it "[config] should write configuration settings" do
		create_project
		run_command_successfully(["config", "test_setting", true]).should == true
		Glyph::CONFIG.get(:test_setting).should == true
		Glyph::PROJECT_CONFIG.read
		Glyph::PROJECT_CONFIG.get('test_setting').should == true
		Glyph::GLOBAL_CONFIG.read
		Glyph::GLOBAL_CONFIG.get('test_setting').should_not == true
		run_command_successfully(["config", "-g", "another.test", "something else"]).should == true
		(Glyph::SPEC_DIR/'.glyphrc').exist?.should == true
		Glyph::CONFIG.get("another.test").should == "something else"
		Glyph::PROJECT_CONFIG.read
		Glyph::PROJECT_CONFIG.get('another.test').should_not == "something else"
		Glyph::GLOBAL_CONFIG.read
		Glyph::GLOBAL_CONFIG.get('another.test').should == "something else"
		run_command_successfully(["config", "-g", "yet.another.test", "something else", "extra argument"]).should == false
		(Glyph::SPEC_DIR/'.glyphrc').unlink
	end

	it "[add] should create a new text file" do
		create_project
		run_command_successfully(["add", "test.textile"]).should == true
		(Glyph::PROJECT/'text/test.textile').exist?.should == true
	end

	it "[compile] should compile the project" do
		create_project
		run_command(["compile"]).match(/test_project\.html/m).should_not == nil
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

	it "[compile] should support a custom source file" do
		create_project
		file_copy Glyph::PROJECT/'document.glyph', Glyph::PROJECT/'custom.glyph'
		run_command(["compile", "-s", "custom.glyph"]).match(/custom\.glyph/m).should_not == nil
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

	it "[compile] should continue execution in case of macro errors" do
		create_project
		text = %{
			=>[#invalid1]
			=>[#invalid2]
			=>[#valid]
			&[test]
			&[invalid3]
			#[valid|Valid bookmark]
		}
		file_write Glyph::PROJECT/'document.glyph', text
		res = run_command(['-d', "compile"])
		res.match(/Bookmark 'invalid1' does not exist/).should_not == nil
		res.match(/Bookmark 'invalid2' does not exist/).should_not == nil
		res.match(/Bookmark 'valid' does not exist/).should == nil
		res.match(/Snippet 'invalid3' does not exist/).should_not == nil
	end

	it "[compile] should not compile the project in case of an unknown output format" do
		run_command_successfully(["compile", "-f", "wrong"]).should == false
	end


end
