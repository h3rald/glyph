#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Interpreter do

	before do
		delete_project
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
	end


	after do
		delete_project
	end

	it "should process text and run simple macros" do
		define_em_macro
		text = "This is a em[test]. It em[should] work."
		interpret text
		@p.document.output.should == "This is a <em>test</em>. It <em>should</em> work."
		text2 = "This is pointless, but valid: em[]. This em[will] though."
		interpret text2
		@p.document.output.should == "This is pointless, but valid: <em></em>. This <em>will</em> though."
	end

	it "should process and run complex macros" do
		define_ref_macro
		text = "This is a ref[http://www.h3rald.com|test]."
		interpret text
		@p.document.output.should == "This is a <a href=\"http://www.h3rald.com\">test</a>."
	end

	it "should support multiline macros" do
		define_ref_macro
		text = %{This is a test containing a ref[
		http://www.h3rald.com
		|
		multiline
		
		] macro.}
		interpret text
		@p.document.output.should == %{This is a test containing a <a href="http://www.h3rald.com">multiline</a> macro.}
	end

	it "should support escape characters" do
		define_em_macro
		text = %{This text contains em[
			some escaped em\\[content\\]... etc.].}
		interpret text
		@p.document.output.should == %{This text contains <em>some escaped em[content]... etc.</em>.}
	end

	it "should support nested macros" do
		define_em_macro
		define_ref_macro
		text = %{This is an ref[#test|em[emphasized] link]}
		interpret text
		@p.document.output.should == %{This is an <a href="#test"><em>emphasized</em> link</a>}
	end

	it "should store syntax node information in context" do
		define_em_macro
		define_ref_macro
		count = 0
		Glyph.macro :test_node do |node|
			node.ascend do |n| 
				count+=1
			end
			node.parent[:macro]
		end
		text = %{Test em[test_node[em[test_node[---]]]].}
		interpret text
		@p.document.output.should == "Test <em>em</em>."
		count.should == 8
	end

	it "should process document.glyph" do
		interpret file_load(Glyph::PROJECT/'document.glyph')
		macros = []
		@p.document.structure.descend do |n, level|
			macros << {n[:macro] => level} if n[:macro]
		end
		macros.should == [{:"@" => 1},{:textile => 2},{:section => 3}, {:header => 4}, 
			{:"@" => 4}, {:textile => 5}, {:section => 6}, {:header => 7}, 
			{:"@" => 1}, {:markdown => 2},{:section => 3}, {:header => 4}]
	end


	it "should provide diagnostic information on errors" do
		failure = "Syntax Error: Missing delimiter?\n -> -- [Line 1, Column 13]"
		# This is probably the only type of error recognized which can occur at parser level
		lambda { interpret "section[em[]" }.should raise_error(RuntimeError, failure)
	end

end
