#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Preprocessor::Actions do

	before do
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
		@p = Glyph::Preprocessor
	end

	after do
		delete_project
	end

	def define_em_macro
		@p.macro :em do |value, context| 
			%{<em>#{value}</em>}
		end
	end

	it "should store IDs" do
		@p.process("this is a #[test|test].").should == "this is a <a id=\"test\">test</a>."
		Glyph::IDS.include?(:test).should == true 
		lambda { @p.process("this is a #[test|test].")}.should raise_error(MacroError, "[--] #: ID 'test' already exists.")
	end

	it "should retrieve snippets" do
		@p.process("Testing a snippet: &[test].").should == "Testing a snippet: This is a \nTest snippet."
		lambda { @p.process("Testing &[wrong].")}.should raise_error(MacroError)
	end
	
	it "should be possible to use macros in snippets" do
		define_em_macro
		Glyph::SNIPPETS[:a] = "this is a em[test] &[b]"
		Glyph::SNIPPETS[:b] = "and another em[test]"
		text = "TEST: &[a]"
		@p.process(text).should == "TEST: this is a <em>test</em> and another <em>test</em>"
	end

end	
