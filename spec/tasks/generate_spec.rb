#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "generate" do

	before do
		create_project
	end

	after do
		delete_project
	end

	it ":document should generate Glyph.document" do
		lambda { Glyph.run! 'generate:document'}.should_not raise_error
		Glyph.document.structure.children.length.should > 0
	end

	it ":html should generate a standalone html document" do
		lambda { Glyph.run! 'generate:html'}.should_not raise_error
		(Glyph::PROJECT/'output/html/test_project.html').exist?.should == true
	end

	it ":html should not copy images in Lite mode"

	it "should copy images" do
		dir = (Glyph::PROJECT/'images/test').mkpath
		file_copy Glyph::HOME/'spec/files/ligature.jpg', Glyph::PROJECT/'images/test' 
		lambda { Glyph.run! 'generate:html' }.should_not raise_error
		(Glyph::PROJECT/'output/html/images/test/ligature.jpg').exist?.should == true
	end

end
