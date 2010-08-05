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

	it "should collect snippet stats" do 
		Glyph.run "project:stats", :snippets
		Glyph::STATS[:snippets].blank?.should == false
		Glyph::STATS[:snippets].should == {
			:ids=>{:test=>{:total=>2, :files=>{"document.glyph"=>1, "text/references.glyph" => 1}}}, 
			:total_instances=>2, 
			:total_used_definitions=>1, 
			:total_unused_definitions=>1, 
			:unused_definitions=>[:unused]
		}
		Glyph.run! 'project:stats', :snippet, 'test'
		Glyph::STATS[:snippet].should == ["document.glyph", "text/references.glyph"]
	end

	it "should collect global stats" do
		lambda { Glyph.run 'project:stats' }.should_not raise_error
		Glyph.document.blank?.should == false
		Glyph.run "project:stats"
		Glyph::STATS[:bookmarks].blank?.should == false
		Glyph::STATS[:links].blank?.should == false
		Glyph::STATS[:snippets].blank?.should == false
		Glyph::STATS[:macros].blank?.should == false
		Glyph::STATS[:files].should == {:layouts=>0, :images=>1, :styles=>1, :text=>4, :lib=>0}
	end
	

end
