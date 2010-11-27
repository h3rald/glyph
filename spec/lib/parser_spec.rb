#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Parser do

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
		tree = document_node
		tree << text_node("\ntest #1\n")
		tree << macro_node(:section)
		(tree&1) << p_node(0)
		section_0 = tree&1&0
		section_0 << macro_node(:header)
		section_0.children.last << p_node(0)
		header_0 = section_0&0&0
		header_0 << text_node("Testing...")
		section_0 << text_node("\n\t")
		section_0 << macro_node(:"=>")
		section_0.children.last << p_node(0)
		link_0 = section_0.children.last&0
		link_0 << text_node("#something")
		section_0 << text_node("\n\tTest.\n\t")
		section_0 << macro_node(:section)
		section_0.children.last << p_node(0)
		section_1 = section_0.children.last&0
		section_1 << text_node("\n\t\t")
		section_1 << macro_node(:header)
		section_1.children.last << p_node(0)
		header_1 = section_1.children.last&0
		header_1 << text_node("Another test")
		section_1 << text_node("\nContents")
		section_0 << text_node("\n")
		parse_text(text).should == tree
	end

	it "should recognize escape sequences" do
		text = "section[This is a test test\\[\\]\\]\\[ ]"
		tree = document_node
		tree << macro_node(:section)
		macro_0 = p_node( 0)
	 	macro_0	<< text_node("This is a test test")
		macro_0 << escape_node("\\[")
		macro_0 << escape_node("\\]")
		macro_0 << escape_node("\\]")
		macro_0 << escape_node("\\[")
		macro_0 << text_node(" ")
		(tree&0) << macro_0
		parse_text(text).should == tree
	end

	it "should raise an error if a standard macro is not closed" do
		text = "test\nsection[test\\]\ntest"
		lambda { puts parse_text(text).inspect }.should	raise_error(Glyph::SyntaxError, "-- [3, 4] Macro 'section' not closed")
	end

	it "should not parse macros within escaping macros" do
		text = "test1[= abc test2[This macro is escaped]\n cde=]"
		tree = document_node
		tree << macro_node(:test1, :escape => true)
		macro_0 = p_node(0) 
		macro_0 << text_node(" abc test2[This macro is escaped]\n cde", :escaped => true)
		(tree&0) << macro_0
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

	it "should parse positional parameters (parameters)" do
		text = "test[aaa =>[test2[...]|test3[...]].]"
		tree = document_node
		tree << macro_node(:test)
		macro_0 = p_node 0
		macro_0 << text_node('aaa ')
		macro_0 << macro_node("=>")
		(tree&0) << macro_0
		macro_01_p0 = p_node 0
		macro_01_p0 << macro_node(:test2)
		(macro_0&1) << macro_01_p0
		macro_010 = p_node 0
		macro_010 << text_node("...")
		(macro_01_p0&0) << macro_010
		macro_01_p1 = p_node 1
		macro_01_p1 << macro_node(:test3)
		(macro_0&1) << macro_01_p1
		macro_011 = p_node 0
		macro_011 << text_node("...")
		(macro_01_p1&0) << macro_011
		macro_0 << text_node(".")
		parse_text(text).should == tree
	end

	it "should not allow parameters outside macros" do
		text = "... | test[...]"
		lambda { puts parse_text(text).inspect }.should raise_error(Glyph::SyntaxError, "-- [1, 5] Parameter delimiter '|' not allowed here")
	end

	it "should recognize escaped pipes" do
		text = "\\| test \\| test[=this \\| is|a \\|test=]"
		tree = document_node
		tree << escape_node("\\|")
		tree << text_node(" test ")
		tree << escape_node("\\|")
		tree << text_node(" ")
		tree << macro_node(:test, :escape => true)
		tree.children.last << p_node(0)
		test_0 = tree.children.last&0
		test_0 << text_node("this ", :escaped => true)
		test_0 << escape_node("\\|")
		test_0 << text_node(" is", :escaped => true)
		tree.children.last << p_node(1)
		test_1 = tree.children.last&1
		test_1 << text_node("a ", :escaped => true)
		test_1 << escape_node("\\|")
		test_1 << text_node("test", :escaped => true)
		parse_text(text).should == tree
	end

	it "should parse named parameters (attributes)" do
		text = "test[@first[test1] @second[=test2[...]=].]"
		tree = document_node
		tree << macro_node(:test)
		first = a_node :first
		first << text_node("test1")
		macro_0 = p_node(0)
		macro_0 << text_node(" ")
		macro_0 << text_node(".")
		second = a_node :second, :escape=> true
		second << text_node("test2[...]", :escaped => true)
		(tree&0) << macro_0
		(tree&0) << first
		(tree&0) << second
		parse_text(text).should == tree
	end

	it "should not parse parameters inside attributes" do
		text = "test[@attr[test|...]]"
		lambda { puts parse_text(text).inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 16] Parameter delimiter '|' not allowed here")
	end

	it "should parse attributes inside parameters" do
		text = "test[parameter 1|@par[...] test]"
		tree = document_node
		tree << macro_node(:test)
		tree.children.last << p_node(0)
		test_0 = tree.children.last&0
		test_0 << text_node("parameter 1")
		tree.children.last << p_node(1)
		tree.children.last << a_node(:par)
		test_1 = tree.children.last&1
		par = tree.children.last&2
		par << text_node("...")
		test_1 << text_node(" test")
		parse_text(text).should == tree
	end

	it "should not allow attribute nesting" do
		text = "... test[@par1[@par2[...]...]]"
		lambda { puts parse_text(text).inspect}.should raise_error(Glyph::SyntaxError, "-- [1, 22] Attributes cannot be nested")
	end

	it "should parse macros nested in attributes" do
		text = "test[@a[test1[@b[...]@c[...]]]]"
		tree = document_node
		tree << macro_node(:test)
		a = a_node :a
		a << macro_node(:test1)
		(tree&0) << a
		b = a_node :b
		b << text_node('...')
		(a&0) << b
		c = a_node :c
		c << text_node('...')
		(a&0) << c
		parse_text(text).should == tree
	end

	it "should parse parameters in nested macros" do
		text = "test[...|test1[a|b]|...]"
		tree = document_node
		tree << macro_node(:test)
		macro_0_p0 = p_node 0
		macro_0_p0 << text_node("...")
		(tree&0) << macro_0_p0
		macro_0_p1 = p_node 1
		macro_0_p1 << macro_node(:test1)
		(tree&0) << macro_0_p1
		macro_01_p0 = p_node 0
		macro_01_p0 << text_node('a')
		(macro_0_p1&0) << macro_01_p0
		macro_01_p1 = p_node 1
		macro_01_p1 << text_node('b')
		(macro_0_p1&0) << macro_01_p1
		macro_0_p2 = p_node 2
		macro_0_p2 << text_node("...")
		(tree&0) << macro_0_p2
		parse_text(text).should == tree
	end

	it "should handle escaped sequences before macro names" do
		text = "abc\\.test[...]"
		tree = document_node
		tree << text_node("abc")
		tree << escape_node("\\.")
		tree << macro_node(:test)
		macro_0 = p_node(0) 
		macro_0 << text_node("...")
		(tree&2) << macro_0
		parse_text(text).should == tree
	end

	it "should ignore parameters for empty macros" do
		text = "toc[]"
		tree = document_node
		tree << macro_node(:toc)
		parse_text(text).should == tree
	end

	it "should allow macro composition" do
		parse_text("test[...|a/b/c[...]]").should == parse_text("test[...|a[b[c[...]]]]")
		parse_text(" /test[...]").should == parse_text(" test[...]")
		parse_text(" test/[...]").should == parse_text(" test[...]")
		parse_text("a/b/c[=test[...]=]").should == parse_text("a[b[c[=test[...]=]]]")
	end

end
