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

	it "section (topic)" do
		lambda { output_for("contents[section[@src[test]]]") }.should raise_error(Glyph::MacroError, "Macro 'section' requires a 'title' attribute") 
		interpret("contents[section[@src[a/web1.glyph]@title[Test]]]")
		topic = @p.document.topics[0]
		topic.blank?.should == false 
		topic[:id].should == :t_0 
		topic[:title].should == "Test" 
		topic[:src].should == "a/web1.glyph"
		topic[:contents].match(/id="w1_3"/).blank?.should == false
		@p.document.output.should == "" 
		Glyph['document.output'] = 'html'
		Glyph.run! 'load:macros'
		output_for("contents[section[@src[a/web1.glyph]@title[Test]]]").match(/id="w1_3"/).blank?.should == false
	end

	it "navigation" do
		Glyph.run! 'generate:web'
		web1 = Glyph.file_load(Glyph::PROJECT/'output/web/a/web1.html')
		web2 = Glyph.file_load(Glyph::PROJECT/'output/web/a/b/web2.html')
		web1.match(%{<ul class="navigation"><li><a href="index.html">Contents</a></li><li><a href="a/b/web2.html">Next &rarr;</a></li></ul>}).blank?.should == false
		web2.match(%{<ul class="navigation"><li><a href="a/web1.html">&larr; Previous</a></li><li><a href="index.html">Contents</a></li></ul>}).blank?.should == false
	end

end	
