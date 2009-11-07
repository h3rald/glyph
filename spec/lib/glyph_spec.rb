#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph do

	before do
		Glyph.enable 'project:create'
	end

	it "should initialize a rake app and tasks" do
		Glyph::APP.tasks.length.should > 0
	end

	it "should run rake tasks" do
		create_project_dir
		lambda { Glyph.run 'project:create', @project }.should_not raise_error
		lambda { Glyph.run! 'project:create', @project }.should raise_error
		delete_project_dir
		create_project_dir
		lambda { Glyph.run! 'project:create', @project }.should_not raise_error
	end

	it "should provide a way to get and set configuration settings" do
		lambda { Glyph.cfg :quiet => false }.should_not raise_error
		Glyph::CONFIG[:quiet].should == false
		lambda { Glyph.cfg :quiet }.should_not raise_error
		Glyph.cfg(:quiet).should == Glyph::CONFIG[:quiet]
		Glyph.cfg :quiet => true
	end

end
