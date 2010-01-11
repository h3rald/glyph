#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "load" do

	before do
		create_project
	end

	after do
		delete_project
	end
	
	it "[snippets] should load snippet definitions" do
		lambda { Glyph.run! 'load:snippets'}.should_not raise_error
		Glyph::SNIPPETS[:test].blank?.should == false
	end

	it "[macros] should load macro definitions" do
		lambda { Glyph.run! 'load:macros'}.should_not raise_error
		Glyph::MACROS['note'].blank?.should == false
	end

end
