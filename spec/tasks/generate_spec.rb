#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "generate" do

	before do
		create_project
	end

	after do
		delete_project
	end
	
	it ":document should generate Glyph::DOCUMENT" do
		lambda { Glyph.run! 'generate:document'}.should_not raise_error
		Glyph::DOCUMENT.children.length.should > 0
	end

	it ":html should generate a standalone html document" do
		lambda { Glyph.run! 'generate:html'}.should_not raise_error
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

end
