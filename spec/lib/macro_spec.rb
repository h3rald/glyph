#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Macro do

	before do
		Glyph.macro :test do
			"Test: #{@value}"
		end
		create_tree = lambda {|text| }
		create_doc = lambda {|tree| }
		@text = "test[section[header[Test!|test]]]"
		@tree = create_tree @text 
		@doc = create_doc @tree
		@node = {:macro => :test, :value => "Testing...", :source => "--", :document => @doc}.to_node
		@macro = Glyph::Macro.new @node
	end

	it "should raise macro errors" do
		lambda { @macro.macro_error "Error!" }.should raise_error(MacroError)
		
	end

	it "should interpret strings" do
		@macro.interpret("test[--]").should == "Test: --"
	end

	it "should not interpret escaped macros" do
		Glyph.macro :int_1 do
			"->#{interpret(@value)}<-"
		end
		Glyph.macro :int_2 do
			"=>#{interpret(@value)}<="
		end
		text1 = "int_1[int_2[Test]]"
		text2 = "int_1[=int_2[Test]=]"
		text3 = "int_1[=int_2\\[Test\\]=]"
		text4 = "int_2[int_1[=int_1[wrong_macro[Test]]=]]"
		@macro.interpret(text1).should == "->=>Test<=<-"
		@macro.interpret(text2).should == "->int_2\\[Test\\]<-"
		@macro.interpret(text3).should == "->int_2\\[Test\\]<-"
		@macro.interpret(text4).should == "=>->int_1\\[wrong_macro\\[Test\\]\\]<-<="
	end

	it "should store and check bookmarks" do
		h = { :id => "test2", :title => "Test 2" }
		@macro.bookmark h
		@doc.bookmark?(:test2).should == h
		@macro.bookmark?(:test2).should == h
	end

	it "should store and check headers" do
		h = { :level => 2, :id => "test3", :title => "Test 3" }
		@macro.header h
		@doc.header?("test3").should == h
		@macro.header?("test3").should == h
	end

	it "should store placeholders" do
		@macro.placeholder { |document| }
		@doc.placeholders.length.should == 1
	end

	it "should execute" do
		@macro.execute.should == "Test: Testing..."
	end

	it "should detect mutual inclusion" do
		delete_project
		create_project
		Glyph.run! 'load:macros'
		Glyph::SNIPPETS[:inc] = "Test &[inc]"
		lambda {@macro.interpret("&[inc] test")}.should raise_error(
			MutualInclusionError, "Mutual inclusion\n -> source: &[inc]\n -> path: test/&/&")
	end

end
