#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
	end

	after do
		delete_project
	end

	it "anchor" do
		interpret "this is a #[test|test]."
		doc = @p.document
		doc.output.should == "this is a <a id=\"test\">test</a>."
		doc.bookmarks.has_key?(:test).should == true 
		lambda { interpret "this is a #[test|test]. #[test|This won't work!]"; @p.document }.should raise_error(MacroError)
	end

	it "snippet" do
		define_em_macro
		interpret "Testing a snippet: &[test]."
		@p.document.output.should == "Testing a snippet: This is a \nTest snippet."
		interpret("Testing &[wrong].")
		@p.document.output.should == "Testing [SNIPPET 'wrong' NOT PROCESSED]." 
		Glyph::SNIPPETS[:a] = "this is a em[test] &[b]"
		Glyph::SNIPPETS[:b] = "and another em[test]"
		text = "TEST: &[a]"
		interpret text
		@p.document.output.should == "TEST: this is a <em>test</em> and another <em>test</em>"
	end

	it "section, chapter, header" do
		text = "chapter[header[Chapter X] ... section[header[Section Y|sec-y] ... section[header[Another section] ...]]]"
		l = cfg("structure.first_header_level")
		interpret text
		doc = @p.document
		doc.output.gsub(/\n|\t/, '').should == %{<div class="chapter">
					<h#{l} id="h_1">Chapter X</h#{l}> ... 
					<div class="section">
					<h#{l+1} id="sec-y">Section Y</h#{l+1}> ... 
						<div class="section">
						<h#{l+2} id="h_3">Another section</h#{l+2}> ...
						</div>
					</div>
				</div>
		}.gsub(/\n|\t/, '')
		doc.bookmark?(:"sec-y").should == {:id => :"sec-y", :title => "Section Y"} 
	end

	it "include" do
		l = cfg("structure.first_header_level")
		Glyph.config_override "filters.by_extension", true
		text = file_load(Glyph::PROJECT/'text/container.textile')
		interpret text
		@p.document.output.gsub(/\n|\t|_\d{1,3}/, '').should == %{
			<div class="section">
			<h#{l} id="h_1">Container section</h#{l}>
			This is a test.
				<div class="section">
				<h#{l+1} id="h_2">Test Section</h#{l+1}>	
				<p>&#8230;</p>
				</div>
			</div>
		}.gsub(/\n|\t|_\d{1,3}/, '')
	end


	it "style" do
		interpret "style[test.sass]"
		@p.document.output.gsub(/\n|\t/, '').should == "<style type=\"text/css\">#main {  background-color: #0000ff; }</style>"
	end	

	it "escape" do
		define_em_macro
		text = %{This is a test em[This can .[=contain test[macros em[test]]=]]}		
		interpret text
		@p.document.output.should == %{This is a test <em>This can contain test[macros em[test]]</em>}
	end

	it "ruby" do
		interpret "2 + 2 = %[2+2]"
		@p.document.output.should == %{2 + 2 = 4}
	end

	it "config" do
		Glyph.config_override "test.setting", "TEST"
		interpret "test.setting = $[test.setting]"
		@p.document.output.should == %{test.setting = TEST}
	end

	it "toc" do
		file_copy Glyph::PROJECT/'../files/document_with_toc.glyph', Glyph::PROJECT/'document.glyph'
		interpret file_load(Glyph::PROJECT/'document.glyph')
		doc = @p.document
		doc.output.gsub!(/\n|\t/, '')
		doc.output.slice(/(.+?<\/div>)/, 1).should == %{
			<div class="contents">
			<span class="header" id="h_toc">Table of Contents</span>
			<ul class="toc">
				<li class="toc-section"><a href="#h_1">Container section</a></li>
				<li><ul>
					<li class="toc-section"><a href="#h_2">Test Section</a></li>
				</ul></li>
				<li class="toc-section"><a href="#md">Markdown</a></li>
			</ul>
			</div>
		}.gsub(/\n|\t/, '')
	end

	it "link" do
		text = %{
			link[#test_id]
			link[#test_id2]
			#[test_id|Test #1]
			#[test_id2|Test #2]
		}
		interpret text
		@p.document.output.gsub(/\n|\t/, '').should == %{
			<a href="#test_id">Test #1</a>
			<a href="#test_id2">Test #2</a>
			<a id="test_id">Test #1</a>
			<a id="test_id2">Test #2</a>
		}.gsub(/\n|\t/, '')
	end

	it "fmi" do
		interpret "fmi[this topic|#test] #[test|Test]"
		@p.document.output.should == %{<span class="fmi">
			for more information on this topic, 
			see <a href="#test">Test</a></span> <a id="test">Test</a>}.gsub(/\n|\t/, '')
	end	


end	
