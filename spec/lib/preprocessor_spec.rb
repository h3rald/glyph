#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Preprocessor do

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
		@p.macro :em do |params, meta| 
			%{<em>#{params[0]}</em>}
		end
	end

	def define_ref_macro
		@p.macro :ref do |params, meta|
			%{<a href="#{params[0]}">#{params[1]}</a>}
		end
	end

	it "should define macros" do
		lambda { define_em_macro }.should_not raise_error
		lambda { define_ref_macro }.should_not raise_error
		Glyph::MACROS.include?(:em).should == true
		Glyph::MACROS.include?(:ref).should == true
	end

	it "should process text and run simple macros" do
		define_em_macro
		text = "This is a em[test]. It em[should] work."
		@p.process(text).should == "This is a <em>test</em>. It <em>should</em> work."
		text2 = "This is pointless, but valid: em[]. This em[will] though."
		@p.process(text2).should == "This is pointless, but valid: <em></em>. This <em>will</em> though."
	end

	it "should process and run complex macros" do
		define_ref_macro
		text = "This is a ref[http://www.h3rald.com|test]."
		@p.process(text).should == "This is a <a href=\"http://www.h3rald.com\">test</a>."
	end

	it "should support macro aliases" do
		define_ref_macro
		lambda { @p.macro_alias("=>", :ref)}.should_not raise_error
		text = "This is a =>[http://www.h3rald.com|test]."
		@p.process(text).should == "This is a <a href=\"http://www.h3rald.com\">test</a>."
	end
	
	it "should store IDs" do
		@p.process("this is a #[test|test].").should == "this is a <a id=\"test\">test</a>."
		Glyph::IDS.include?(:test).should == true 
		lambda { @p.process("this is a #[test|test].")}.should raise_error(MacroError, "#(): ID 'test' already exists.")
	end

	it "should retrieve snippets" do
		@p.process("Testing a snippet: &[test].").should == "Testing a snippet: This is a \nTest snippet."
		lambda { @p.process("Testing &[wrong].")}.should raise_error(MacroError)
	end

	it "should support multiline macros" do
		define_ref_macro
		text = %{This is a test containing a ref[
		http://www.h3rald.com
		|
		multiline
		
		] macro.}
		@p.process(text).should == %{This is a test containing a <a href="http://www.h3rald.com">multiline</a> macro.}
	end

	it "should support escape characters" do
		define_em_macro
		text = %{This text contains em[
			some escaped em\[content\]...) etc.].}
		@p.process(text).should == %{This text contains <em>some escaped em(content)... etc.</em>.}
	end


end


