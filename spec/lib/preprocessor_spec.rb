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
		@p.macro :em do |node| 
			%{<em>#{node[:value]}</em>}
		end
	end

	def define_ref_macro
		@p.macro :ref do |node|
			params = @p.get_params_from node
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
			some escaped em\\[content\\]... etc.].}
		@p.process(text).should == %{This text contains <em>some escaped em[content]... etc.</em>.}
	end

	it "should support nested macros" do
		define_em_macro
		define_ref_macro
		text = %{This is an ref[#test|em[emphasized] link]}
		@p.process(text).should == %{This is an <a href="#test"><em>emphasized</em> link</a>}
	end

	it "should support escaping macros" do
		define_em_macro
		text = %{This is a test em[This can %[=contain test[macros em[test]]=]]}		
		@p.process(text).should == %{This is a test <em>This can contain test[macros em[test]]</em>}
	end

	it "should store syntax node information in context" do
		define_em_macro
		define_ref_macro
		count = 0
		@p.macro :test_node do |node|
			node.ascend do |n| 
				count+=1
			end
			node.parent[:macro]
		end
		text = %{Test em[test_node[em[test_node[---]]]].}
		@p.process(text).should == "Test <em>em</em>."
		count.should == 8
	end

	it "should process document.glyph" do
		c = @p.process_document
		macros = []
		macros.should == []
		#TODO
	end

end
