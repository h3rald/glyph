#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "project:create" do

	before do
		@rake = Glyph::APP
		@rake['project:create'].reenable
		create_project_dir
	end

	after do
		delete_project_dir
	end

	it "Should not create a new project if no valid directory is supplied" do
		lambda { @rake['project:create'].invoke '.' }.should raise_error
		@rake['project:create'].reenable
		lambda { @rake['project:create'].invoke 'test_dir' }.should raise_error
	end

	it "Should create a new project if an existing empty directory is supplied" do
		lambda { @rake['project:create'].invoke @project }.should_not raise_error
		(@project/'lib/tasks').exist?.should == true
		(@project/'lib/macros').exist?.should == true
		(@project/'config').exist?.should == true
		(@project/'text').exist?.should == true
		(@project/'layouts').exist?.should == true
		(@project/'styles').exist?.should == true
		(@project/'assets').exist?.should == true
		(@project/'output').exist?.should == true
		(@project/'lib').exist?.should == true
	end

	it "Should add new files to project" do
		create_project
		lambda { @rake['project:add'].invoke 'test.textile'}.should_not raise_error
		(@project/'text/test.textile').exist?.should == true
		lambda { @rake['project:add'].invoke 'test.textile'}.should raise_error
		lambda { @rake['project:add'].invoke 'chapter1/test.textile'}.should_not raise_error
		(@project/'text/chapter1/test.textile').exist?.should == true
	end

end
