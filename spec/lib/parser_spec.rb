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
			:segments => [],
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
		lambda { puts parse_text(text).inspect }.should	raise_error(Glyph::SyntaxError, "-- [3, 4] Macro 'section' not closed")
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
		lambda  { puts parse_text(text).inspect }.should raise_error(Glyph::SyntaxError, "-- [1, 41] Cannot nest escaping macro 'test2' within escaping macro 'test1'")
	end
	
	it "should raise an error if an escaping macro is not closed" do
		text = "test1[= abc test2[This macro is escaped]\n cde] test"
		lambda { puts parse_text(text).inspect }.should	raise_error(Glyph::SyntaxError, "-- [2, 10] Escaping macro 'test1' not closed")
	end

	it "should raise errors if unescaped brackets are found" do
		lambda { puts parse_text(" ] test[...] dgdsg").inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 2] Macro delimiter ']' not escaped")
		lambda { puts parse_text("[ test[...] dgdsg").inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 1] Macro delimiter '[' not escaped")
		lambda { puts parse_text(" test[...] [dgdsg]").inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 12] Macro delimiter '[' not escaped")
		lambda { puts parse_text(" test[...] dgdsg [").inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 18] Macro delimiter '[' not escaped")
		lambda { puts parse_text(" test[[...]] dgdsg").inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 7] Macro delimiter '[' not escaped")
	end

	it "should parse positional parameters (segments)" do
		text = "test[aaa =>[test2[...]|test3[...]].]"
		tree = {:type => :document}.to_node
		tree << macro_node(:test)
		(tree&0) << text_node("aaa ")
		(tree&0) << macro_node(:"=>")
		(tree&0&1)[:segments] << {:type => :segment}.to_node
		(tree&0&1)[:segments][0] << macro_node(:test2)
		((tree&0&1)[:segments][0]&0) << text_node("...")
		(tree&0&1)[:segments] << {:type => :segment}.to_node
		(tree&0&1)[:segments][1] << macro_node(:test3)
		((tree&0&1)[:segments][1]&0) << text_node("...")
		(tree&0) << text_node(".")
		parse_text(text).should == tree
	end

	it "should not allow segments outside macros" do
		text = "... | test[...]"
		lambda { puts parse_text(text).inspect }.should raise_error(Glyph::SyntaxError, "-- [1, 5] Segment delimiter '|' not allowed here")
	end

	it "should recognize escaped pipes" do
		text = "\\| test \\| test[=this \\| is|a \\|test=]"
		tree = {:type => :document}.to_node
		tree << text_node("\\| test \\| ")
		tree << macro_node(:test, :escape => true)
		(tree&1)[:segments] << {:type => :segment}.to_node
		(tree&1)[:segments][0] << text_node("this \\| is", :escaped => true) 
		(tree&1)[:segments] << {:type => :segment}.to_node
		(tree&1)[:segments][1] << text_node("a \\|test", :escaped => true) 
		parse_text(text).should == tree
	end

	it "should parse named parameters (attributes)" do
		text = "test[@first[test1] @second[=test2[...]=].]"
		tree = {:type => :document}.to_node
		tree << macro_node(:test)
		(tree&0)[:attributes][:first] = {:type => :attribute, :escape => false}.to_node
		(tree&0)[:attributes][:first] << text_node("test1")
		(tree&0)[:attributes][:second] = {:type => :attribute, :escape => true}.to_node
		(tree&0)[:attributes][:second] << text_node("test2[...]", :escaped => true)
		(tree&0) << text_node(" ")
		(tree&0) << text_node(".")
		parse_text(text).should == tree
	end

	it "should not parse segments inside attributes" do
		text = "test[@attr[test|...]]"
		lambda { puts parse_text(text).inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 16] Segment delimiter '|' not allowed here")
	end

	it "should parse attributes inside segments" do
		text = "test[segment 1|@par[...] test]"
		tree = {:type => :document}.to_node
		tree << macro_node(:test)
		(tree&0)[:segments] << {:type => :segment}.to_node
		(tree&0)[:segments][0] << text_node("segment 1") 
		(tree&0)[:segments] << {:type => :segment}.to_node
		(tree&0)[:attributes][:par] = {:type => :attribute, :escape => false}.to_node
		(tree&0)[:attributes][:par] << text_node("...")
		(tree&0)[:segments][1] << text_node(" test") 
		parse_text(text).should == tree
	end

	it "should not allow attribute nesting" do
		text = "... test[@par1[@par2[...]...]]"
		lambda { puts parse_text(text).inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 22] Attributes cannot be nested")
	end

end
