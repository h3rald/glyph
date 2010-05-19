#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Parser do


	def text_node(value)
		{:type => :text, :value => value}
	end

	def macro_node(name, params={}, order=[], escape=false)
		{
			:type => :macro, 
			:name => name, 
			:params => params, 
			:order => order, 
			:escape => escape
		}
	end

	def parse_text(text)
		Glyph::Parser.new(text).parse
	end

	it "should parse macros" do
		text = %{
test #1
section[header[Testing...]
	=>[#something]
	Test.
	section[
		header[Another test]
Contents]
]}
		tree = {:type => :document}.to_node
		tree << text_node("\ntest #1\n")
		tree << macro_node(:section)
		(tree&1) << macro_node(:header)
		(tree&1&0) << text_node("Testing...")
		(tree&1) << text_node("\n\t")
		(tree&1) << macro_node(:"=>")
		(tree&1&2) << text_node("#something")
		(tree&1) << text_node("\n\tTest.\n\t")
		(tree&1) << macro_node(:section)
		(tree&1&4) << text_node("\n\t\t")
		(tree&1&4) << macro_node(:header)
		(tree&1&4&1) << text_node("Another test")
		(tree&1&4) << text_node("\nContents")
		(tree&1) << text_node("\n")
		parse_text(text).should == tree
	end

	it "should recognize escape sequences" do
		text = "section[This is a test test\\[\\]\\]\\[ ]"
		tree = {:type => :document}.to_node
		tree << macro_node(:section)
		(tree&0) << text_node("This is a test test\\[\\]\\]\\[ ")
		parse_text(text).should == tree
	end

	it "should raise an error if a standard macro is not closed" do
		text = "test\nsection[test\\]\ntest"
		lambda { parse_text(text) }.should	raise_error(Glyph::SyntaxError, "Macro 'section' not closed")
	end

	it "should not parse macros within escaping macros"
	
	it "should raise an error if an escaping macro is not closed"

	it "should parse positional parameters"

	it "should parse named parameters"

	it "should raise an error if a named parameter is within a positional parameter"

	it "should not raise an error if escaped contents are nested"

	it "should include line numbers to localize errors"

end
