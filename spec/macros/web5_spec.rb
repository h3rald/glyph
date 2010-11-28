#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_web_project
		Glyph['document.output'] = 'web5'
		Glyph['document.extension'] = '.html'
		Glyph.run! 'load:all'
	end

	after do
		Glyph.lite_mode = false
		reset_quiet
		delete_project
	end

	it "section (topic)" do
		interpret("section[section[@src[a/web1.glyph]@title[Test]]]")
		topic = @p.document.topics[0]
		topic[:contents].match(/<article>/).blank?.should == false
	end

	it "navigation" do
		Glyph.run! 'generate:web5'
		web1 = Glyph.file_load(Glyph::PROJECT/'output/web5/a/web1.html')
		web2 = Glyph.file_load(Glyph::PROJECT/'output/web5/a/b/web2.html')
		web1.match(%{<nav> | <a href="/index.html">Contents</a> | <a href="/a/b/web2.html">&rarr; Topic #2</a></nav>}).blank?.should == false
		web2.match(%{<nav><a href="/a/web1.html">Topic #1</a> | <a href="/index.html">Contents</a> | </nav>}).blank?.should == false
	end
end	
