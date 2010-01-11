#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "project:create" do

	before do
		create_project_dir
	end

	after do
		delete_project_dir
	end

	it "[create] should not create a new project if no valid directory is supplied" do
		lambda { Glyph.run! 'project:create', '.' }.should raise_error
		lambda { Glyph.run! 'project:create', 'test_dir' }.should raise_error
	end

	it "[create] should create a new project if an existing empty directory is supplied" do
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should_not raise_error
		(Glyph::PROJECT/'lib/tasks').exist?.should == true
		(Glyph::PROJECT/'lib/macros.rb').exist?.should == true
		(Glyph::PROJECT/'text').exist?.should == true
		(Glyph::PROJECT/'layouts').exist?.should == true
		(Glyph::PROJECT/'styles').exist?.should == true
		(Glyph::PROJECT/'assets').exist?.should == true
		(Glyph::PROJECT/'output').exist?.should == true
		(Glyph::PROJECT/'lib').exist?.should == true
	end

	it "[add] should add new files to project" do
		create_project
		lambda { Glyph.run 'project:add', 'test.textile'}.should_not raise_error
		(Glyph::PROJECT/'text/test.textile').exist?.should == true
		lambda { Glyph.run 'project:add', 'test.textile'}.should raise_error
		lambda { Glyph.run 'project:add', 'chapter1/test.textile'}.should_not raise_error
		(Glyph::PROJECT/'text/chapter1/test.textile').exist?.should == true
	end

end
