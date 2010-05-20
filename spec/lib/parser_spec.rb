#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Parser do


	def text_node(value, options={})
		{:type => :text, :value => value}.merge options
	end

	def macro_node(name, options={})
		{
			:type => :macro, 
			:name => name, 
			:escape => false,
			:partitions => [],
			:attributes => {},
		}.merge options
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
		lambda { parse_text(text) }.should	raise_error(Glyph::SyntaxError, "-- [3, 4] Macro 'section' not closed")
	end

	it "should not parse macros within escaping macros" do
		text = "test1[= abc test2[This macro is escaped]\n cde=]"
		tree = {:type => :document}.to_node
		tree << macro_node(:test1, :escape => true)
		(tree&0) << text_node(" abc test2[This macro is escaped]\n cde", :escaped => true)
		parse_text(text).should == tree
	end

	it "should raise an error if escaped contents are nested" do
		text = "test1[= abc test2[=This macro is escaped=]\n cde=]"
		lambda  { parse_text(text) }.should raise_error(Glyph::SyntaxError, "-- [1, 41] Cannot nest escaping macro 'test2' within escaping macro 'test1'")
	end
	
	it "should raise an error if an escaping macro is not closed" do
		text = "test1[= abc test2[This macro is escaped]\n cde] test"
		lambda { parse_text(text) }.should	raise_error(Glyph::SyntaxError, "-- [2, 10] Escaping macro 'test1' not closed")
	end

	it "should parse positional parameters (partitions)"

	it "should parse named parameters (attributes)"

end
