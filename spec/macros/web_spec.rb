#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_web_project
		Glyph['document.output'] = 'web'
		Glyph['document.extension'] = '.html'
		Glyph.run! 'load:all'
	end

	after do
		Glyph.lite_mode = false
		reset_quiet
		delete_project
	end

	it "topic" do
		lambda { output_for("contents[section[@src[test]]]") }.should raise_error(Glyph::MacroError, "Macro 'section' requires a 'title' attribute") 
		interpret("contents[section[@src[a/web1.glyph]@title[Test]]]")
		topic = @p.document.topics[0]
		topic.blank?.should == false 
		topic[:id].should == :t_0 
		topic[:title].should == "Test" 
		topic[:src].should == "a/web1.glyph"
		topic[:contents].match(/id="w1_3"/).blank?.should == false
		@p.document.placeholders.length.should == 2
		@p.document.output.should == "" 
		Glyph['document.output'] = 'html'
		Glyph.run! 'load:macros'
		output_for("contents[section[@src[a/web1.glyph]@title[Test]]]").match(/id="w1_3"/).blank?.should == false
	end

end	
