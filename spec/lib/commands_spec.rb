#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "glyph" do

	it "[init] should create a project in the current directory" do
		Glyph.enable "project:create"
		create_project_dir
		run_command('init').match(/error:/m).should_not == nil
		Dir.chdir @project.to_s
		run_command('init').match(/error:/m).should == nil
		delete_project_dir
	end

end
