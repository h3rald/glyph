#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "project:create" do

	before do
		create_project_dir
	end

	after do
		delete_project_dir
	end

	it "should not create a new project if no valid directory is supplied" do
		lambda { Glyph.run! 'project:create', 'test_dir' }.should raise_error
	end

	it "should create a new project if an existing empty directory is supplied" do
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should_not raise_error
		(Glyph::PROJECT/'lib').exist?.should == true
		(Glyph::PROJECT/'document.glyph').exist?.should == true
		(Glyph::PROJECT/'config.yml').exist?.should == true
		(Glyph::PROJECT/'text').exist?.should == true
		(Glyph::PROJECT/'styles').exist?.should == true
		(Glyph::PROJECT/'images').exist?.should == true
		(Glyph::PROJECT/'output').exist?.should == true
	end

	it "should create a project in a directory containing just Gemfiles or hidden files" do
		file_write Glyph::PROJECT/".test", "..." 
		file_write Glyph::PROJECT/"Gemfile", "..." 
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should_not raise_error
	end
end

describe "project:add" do

	before do
		create_project_dir
	end

	after do
		delete_project_dir
	end


	it "should add new files to project" do
		create_project
		lambda { Glyph.run 'project:add', 'test.textile'}.should_not raise_error
		(Glyph::PROJECT/'text/test.textile').exist?.should == true
		lambda { Glyph.run 'project:add', 'test.textile'}.should raise_error
		lambda { Glyph.run 'project:add', 'chapter1/test.textile'}.should_not raise_error
		(Glyph::PROJECT/'text/chapter1/test.textile').exist?.should == true
	end

end

describe "project:stats" do
	
	before do
		reset_quiet
		create_project_dir
		create_project
		Glyph.file_copy Glyph::SPEC_DIR/'files/document_for_stats.glyph', Glyph::PROJECT/'document.glyph'
		Glyph.file_copy Glyph::SPEC_DIR/'files/references.glyph', Glyph::PROJECT/'text/references.glyph'
	end

	after do
		delete_project_dir
	end

	it "should populate Glyph::STATS and generate a Glyph document" do
		lambda { Glyph.run 'project:stats' }.should_not raise_error
		Glyph.document.blank?.should == false
		Glyph::STATS.blank?.should == false
	end

	it "should collect macro stats" do
		Glyph.run "project:stats", :macros
		Glyph::STATS[:macros].blank?.should == false
		Glyph::STATS[:macros].should == {
			:total_definitions => 9,
			:total_instances => 19,
			:definitions => [:"snippet:", :toc, :include, :textile, 
				:section, :markdown, :snippet, :"#", :"=>"]
		}
		# TODO: stats on a specific macro.
	end

	it "should collect bookmark stats"

	it "should collect link stats"
	
	it "should collect snippet stats"

	it "should collect file stats"

	it "should collect global stats"
	

end
