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
		expect { Glyph.run! 'project:create', 'test_dir' }.to raise_error
	end

	it "should create a new project if an existing empty directory is supplied" do
		expect { Glyph.run! 'project:create', Glyph::PROJECT }.not_to raise_error
		expect((Glyph::PROJECT/'lib').exist?).to eq(true)
		expect((Glyph::PROJECT/'document.glyph').exist?).to eq(true)
		expect((Glyph::PROJECT/'config.yml').exist?).to eq(true)
		expect((Glyph::PROJECT/'text').exist?).to eq(true)
		expect((Glyph::PROJECT/'styles').exist?).to eq(true)
		expect((Glyph::PROJECT/'images').exist?).to eq(true)
		expect((Glyph::PROJECT/'output').exist?).to eq(true)
	end

	it "should create a project in a directory containing just Gemfiles or hidden files" do
		file_write Glyph::PROJECT/".test", "..." 
		file_write Glyph::PROJECT/"Gemfile", "..." 
		expect { Glyph.run! 'project:create', Glyph::PROJECT }.not_to raise_error
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
		expect { Glyph.run 'project:add', 'test.textile'}.not_to raise_error
		expect((Glyph::PROJECT/'text/test.textile').exist?).to eq(true)
		expect { Glyph.run 'project:add', 'test.textile'}.to raise_error
		expect { Glyph.run 'project:add', 'chapter1/test.textile'}.not_to raise_error
		expect((Glyph::PROJECT/'text/chapter1/test.textile').exist?).to eq(true)
	end

end
