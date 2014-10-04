#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Interpreter do

	before do
		delete_project
		create_project
		Glyph.run! 'load:all'
	end


	after do
		reset_quiet
		delete_project
	end

	it "should process text and run simple macros" do
		define_em_macro
		text = "This is a em[test]. It em[should] work."
		expect(output_for(text)).to eq("This is a <em>test</em>. It <em>should</em> work.")
		text2 = "This is pointless, but valid: em[]. This em[will] though."
		expect(output_for(text2)).to eq("This is pointless, but valid: <em></em>. This <em>will</em> though.")
	end

	it "should process and run complex macros" do
		define_ref_macro
		text = "This is a ref[http://www.h3rald.com|test]."
		interpret text
		expect(@p.document.output).to eq("This is a <a href=\"http://www.h3rald.com\">test</a>.")
	end

	it "should support multiline macros" do
		define_ref_macro
		text = %{This is a test containing a ref[
		http://www.h3rald.com
		|
		multiline
		
		] macro.}
		interpret text
		expect(@p.document.output).to eq(%{This is a test containing a <a href="http://www.h3rald.com">multiline</a> macro.})
	end

	it "should support escape characters" do
		define_em_macro
		text = %{This text contains em[
			some escaped em\\[content\\]... etc.].}
		interpret text
		expect(@p.document.output).to eq(%{This text contains <em>some escaped em[content]... etc.</em>.})
	end

	it "should support nested macros" do
		define_em_macro
		define_ref_macro
		text = %{This is an ref[#test|em[emphasized] link]}
		interpret text
		expect(@p.document.output).to eq(%{This is an <a href="#test"><em>emphasized</em> link</a>})
	end

	it "should store syntax node information in context" do
		define_em_macro
		define_ref_macro
		Glyph.macro :test_node do |node|
			node.parent_macro[:name]
		end
		text = %{Test em[test_node[em[test_node[---]]]].}
		interpret text
		expect(@p.document.output).to eq("Test <em>em</em>.")
	end

	it "should provide diagnostic information on errors" do
		failure = "-- [1, 12] Macro 'section' not closed"
		expect { interpret("section[em[]").document }.to raise_error(Glyph::SyntaxError, failure)
	end

end
