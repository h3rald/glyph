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
		expect { output_for("section[@src[test]]") }.to raise_error(Glyph::MacroError, "Macro 'section' requires a 'title' attribute") 
		interpret("section[@src[a/web1.glyph]@title[Test]]")
		topic = @p.document.topics[0]
		expect(topic.blank?).to eq(false) 
		expect(topic[:id]).to eq(:t_0) 
		expect(topic[:title]).to eq("Test") 
		expect(topic[:src]).to eq("a/web1.glyph")
		expect(topic[:contents].match(/id="w1_3"/).blank?).to eq(false)
		Glyph['document.output'] = 'html'
		Glyph.run! 'load:macros'
		expect(output_for("contents[section[@src[a/web1.glyph]@title[Test]]]").match(/id="w1_3"/).blank?).to eq(false)
	end

	it "navigation" do
		Glyph.run! 'generate:web'
		web1 = compact_html Glyph.file_load(Glyph::PROJECT/'output/web/a/web1.html')
		web2 = compact_html Glyph.file_load(Glyph::PROJECT/'output/web/a/b/web2.html')
		expect(web1.match(%{<div class="navigation"> | <a href="/index.html">Contents</a> | <a href="/a/b/web2.html">Topic #2</a></div>}).blank?).to eq(false)
		expect(web2.match(%{<div class="navigation"><a href="/a/web1.html">Topic #1</a> | <a href="/index.html">Contents</a> | </div>}).blank?).to eq(false)
	end

	it "toc should only list topics" do
		Glyph.run! 'generate:web'
		index = Glyph.file_load(Glyph::PROJECT/'output/web/index.html')
		expect(index.match(%{<li class="section"><a href="#h_1">Web Document</a></li>}).blank?).to eq(true)
		expect(index.match(%{href="/a/web1.html#h_3"}).blank?).to eq(false)
		expect(index.match(%{href="/a/b/web2.html#h_7"}).blank?).to eq(false)
		web1 = Glyph.file_load(Glyph::PROJECT/'output/web/a/web1.html')
    expect(web1).to match(/<h2 id="t_0" class="toc">Topic #1<\/h2>/) #  Headers are reset in each topic
		delete_project
		reset_quiet
		create_web_project
		Glyph['document.output'] = 'html'
		Glyph.run! 'generate:html'
		index = compact_html Glyph.file_load(Glyph::PROJECT/'output/html/test_project.html')
    expect(index).to match(%{<li class="section"><a href="#h_3">Topic #1</a></li><li><ol><li class="section"><a href="#h_4">Test #1a</a></li>})
		expect(index.match(%{href="a/web1.html#h_3"}).blank?).to eq(true)
		expect(index.match(%{href="a/b/web2.html#h_7"}).blank?).to eq(true)
		expect(index.match(%{<li class="section"><a href="#h_1">Web Document</a></li>}).blank?).to eq(false)
		expect(index.match(%{href="#h_2"}).blank?).to eq(false)
		expect(index.match(%{href="#h_8"}).blank?).to eq(false) # Header numbers are different...
	end

end	
