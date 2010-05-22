#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Parser do


	def text_node(value, options={})
		{:type => :text, :value => value}.merge options
	end

	def escape_node(value, options={})
		{:type => :escape, :value => value, :escaped => true}.merge options
	end

	def document_node
		{:type => :document, :name => "--".to_sym}.to_node
	end

	def a_node(node, name, options={})
		node[:attributes][name.to_sym] = {:type => :attribute, :name => :"@#{name}", :escape => false}.merge(options).to_node
	end

	def p_node(node, n)
		node[:parameters][n] = {:type => :parameter, :name => :"|#{n}|"}.to_node
	end

	def macro_node(name, options={})
		{
			:type => :macro, 
			:name => name.to_sym, 
			:escape => false,
			:parameters => [],
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
		tree = document_node
		tree << text_node("\ntest #1\n")
		tree << macro_node(:section)
		macro_0 = p_node tree&1, 0
		macro_0 << macro_node(:header)
		macro_00 = p_node macro_0&0, 0
		macro_00 << text_node("Testing...")
		macro_0 << text_node("\n\t")
		macro_0 << macro_node("=>")
		macro_01 = p_node macro_0&2, 0
		macro_01 << text_node("#something")
		macro_0 << text_node("\n\tTest.\n\t")
		macro_0 << macro_node(:section)
		macro_02 = p_node macro_0&4, 0
		macro_02 << text_node("\n\t\t")
		macro_02 << macro_node(:header)
		macro_020 = p_node macro_02&1, 0
		macro_020 << text_node("Another test")
		macro_02 << text_node("\nContents")
		macro_0 << text_node("\n")
		parse_text(text).should == tree
	end

	it "should recognize escape sequences" do
		text = "section[This is a test test\\[\\]\\]\\[ ]"
		tree = document_node
		tree << macro_node(:section)
		macro_0 = p_node(tree&0, 0)
	 	macro_0	<< text_node("This is a test test")
		macro_0 << escape_node("\\[")
		macro_0 << escape_node("\\]")
		macro_0 << escape_node("\\]")
		macro_0 << escape_node("\\[")
		macro_0 << text_node(" ")
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
		p_node(tree&0, 0) << text_node(" abc test2[This macro is escaped]\n cde", :escaped => true)
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
		macro_0 = p_node tree&0, 0
		macro_0 << text_node('aaa ')
		macro_0 << macro_node("=>")
		macro_01_p0 = p_node macro_0&1, 0
		macro_01_p0 << macro_node(:test2)
		macro_010 = p_node macro_01_p0&0, 0
		macro_010 << text_node("...")
		macro_01_p1 = p_node macro_0&1, 1
		macro_01_p1 << macro_node(:test3)
		macro_011 = p_node macro_01_p1&0, 0
		macro_011 << text_node("...")
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
		(tree&4)[:parameters] << {:type => :parameter, :name => :"|0|"}.to_node
		(tree&4)[:parameters][0] << text_node("this ", :escaped => true) 
		(tree&4)[:parameters][0] << escape_node("\\|")
		(tree&4)[:parameters][0] << text_node(" is", :escaped => true) 
		(tree&4)[:parameters] << {:type => :parameter, :name => :"|1|"}.to_node
		(tree&4)[:parameters][1] << text_node("a ", :escaped => true) 
		(tree&4)[:parameters][1] << escape_node("\\|")
		(tree&4)[:parameters][1] << text_node("test", :escaped => true) 
		parse_text(text).should == tree
	end

	it "should parse named parameters (attributes)" do
		text = "test[@first[test1] @second[=test2[...]=].]"
		tree = document_node
		tree << macro_node(:test)
		first = a_node tree&0, :first
		first << text_node("test1")
		macro_0 = p_node(tree&0, 0)
		macro_0 << text_node(" ")
		macro_0 << text_node(".")
		second = a_node tree&0, :second, :escape=> true
		second << text_node("test2[...]", :escaped => true)
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
		(tree&0)[:parameters] << {:type => :parameter, :name => :"|0|"}.to_node
		(tree&0)[:parameters][0] << text_node("parameter 1") 
		(tree&0)[:parameters] << {:type => :parameter, :name => :"|1|"}.to_node
		(tree&0)[:attributes][:par] = {:type => :attribute, :escape => false, :name => :@par}.to_node
		(tree&0)[:attributes][:par] << text_node("...")
		(tree&0)[:parameters][1] << text_node(" test") 
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
		p_node tree&0, 0 
		a = a_node tree&0, :a
		a << macro_node(:test1)
		p_node a&0, 0 
		b = a_node a&0, :b
		b << text_node('...')
		c = a_node a&0, :c
		c << text_node('...')
		parse_text(text).should == tree
	end

	it "should parse parameters in nested macros" do
		text = "test[...|test1[a|b]|...]"
		tree = document_node
		tree << macro_node(:test)
		macro_0_p0 = p_node tree&0, 0
		macro_0_p0 << text_node("...")
		macro_0_p1 = p_node tree&0, 1
		macro_0_p1 << macro_node(:test1)
		macro_01_p0 = p_node macro_0_p1&0, 0
		macro_01_p0 << text_node('a')
		macro_01_p1 = p_node macro_0_p1&0, 1
		macro_01_p1 << text_node('b')
		macro_0_p2 = p_node tree&0, 2
		macro_0_p2 << text_node("...")
		parse_text(text).should == tree
	end

	it "should handle escaped sequences before macro names" do
		text = "abc\\.test[...]"
		tree = document_node
		tree << text_node("abc")
		tree << escape_node("\\.")
		tree << macro_node(:test)
		p_node(tree&2, 0) << text_node("...")
		parse_text(text).should == tree
	end

end
