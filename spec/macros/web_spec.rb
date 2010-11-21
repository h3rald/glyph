#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_web_project
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:all'
	end

	after do
		Glyph.lite_mode = false
		reset_quiet
		delete_project
	end

	it "section (topic)" do
		lambda { output_for("section[@src[test]]") }.should raise_error(Glyph::MacroError, "Macro 'section' requires a 'title' attribute") 
		interpret("section[@src[a/web1.glyph]@title[Test]]")
		topic = @p.document.topics[0]
		topic.blank?.should == false 
		topic[:id].should == :t_0 
		topic[:title].should == "Test" 
		topic[:src].should == "a/web1.glyph"
		topic[:contents].match(/id="w1_3"/).blank?.should == false
		Glyph['document.output'] = 'html'
		Glyph.run! 'load:macros'
		output_for("contents[section[@src[a/web1.glyph]@title[Test]]]").match(/id="w1_3"/).blank?.should == false
	end

	it "navigation" do
		Glyph.run! 'generate:web'
		web1 = Glyph.file_load(Glyph::PROJECT/'output/web/a/web1.html')
		web2 = Glyph.file_load(Glyph::PROJECT/'output/web/a/b/web2.html')
		web1.match(%{<div class="navigation"> | <a href="/index.html">Contents</a> | <a href="/a/b/web2.html">Topic #2</a></div>}).blank?.should == false
		web2.match(%{<div class="navigation"><a href="/a/web1.html">Topic #1</a> | <a href="/index.html">Contents</a> | </div>}).blank?.should == false
	end

	it "toc should only list topics" do
		Glyph.run! 'generate:web'
		index = Glyph.file_load(Glyph::PROJECT/'output/web/index.html')
		index.match(%{<li class="section"><a href="#h_1">Web Document</a></li>}).blank?.should == true
		index.match(%{href="/a/web1.html#h_2"}).blank?.should == false
		index.match(%{href="/a/b/web2.html#h_6"}).blank?.should == false
		delete_project
		reset_quiet
		create_web_project
		Glyph['document.output'] = 'html'
		Glyph.run! 'generate:html'
		index = Glyph.file_load(Glyph::PROJECT/'output/html/test_project.html')
		index.match(%{href="a/web1.html#h_2"}).blank?.should == true
		index.match(%{href="a/b/web2.html#h_6"}).blank?.should == true
		index.match(%{<li class="section"><a href="#h_1">Web Document</a></li>}).blank?.should == false
		index.match(%{href="#h_2"}).blank?.should == false
		index.match(%{href="#h_7"}).blank?.should == false # Header numbers are different...
	end

end	
