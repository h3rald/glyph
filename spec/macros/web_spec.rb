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
		lambda { output_for("topic[@title[test]]") }.should raise_error(Glyph::MacroError, "Macro 'topic' requires a 'src' attribute") 
		lambda { output_for("topic[@src[test]]") }.should raise_error(Glyph::MacroError, "Macro 'topic' requires a 'title' attribute") 
		lambda { output_for("topic[@src[test]@title[test]]") }.should raise_error(Glyph::MacroError, "Macro 'topic' can only be used in document source (document.glyph)") 
		Glyph['system.topics.ignore_file_restrictions'] = true
		interpret("contents[topic[@src[a/web1.glyph]@title[Test]]]")
		topic = @p.document.topics[0]
		topic.blank?.should == false 
		topic[:id].should == :t_0 
		topic[:title].should == "Test" 
		topic[:src].should == "a/web1.glyph"
		topic[:contents].match(/id="w1_3"/).blank?.should == false
		@p.document.output.should == "" 
		Glyph['document.output'] = 'html'
		Glyph.run! 'load:macros'
		output_for("contents[topic[@src[a/web1.glyph]@title[Test]]]").match(/id="w1_3"/).blank?.should == false
		Glyph['system.topics.ignore_file_restrictions'] = false
	end

end	
