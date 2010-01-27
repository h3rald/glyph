#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macros" do

	before do
		create_project
		Glyph.run! 'load:macros'
		@p = Glyph::Interpreter
	end

	after do
		delete_project
	end

	it "should load css and sass files" do
		@p.process("style[test.sass]")[:output].gsub(/\n|\t/, '').should == "<style>#main {  background-color: #0000ff; }</style>"
	end

end	
