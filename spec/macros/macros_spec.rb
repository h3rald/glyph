#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		create_project
		Glyph.run! 'load:all'
	end

	after do
		Glyph.lite_mode = false
		reset_quiet
		delete_project
	end

	it "anchor" do
		interpret "this is a #[test|test]."
		doc = @p.document
		doc.output.should == "this is a <a id=\"test\">test</a>."
		doc.bookmarks.has_key?(:test).should == true 
		lambda { interpret "this is a #[test|test]. #[test|This won't work!]"; @p.document }.should raise_error(Glyph::MacroError)
	end

	it "section, chapter, header" do
		text = "chapter[@title[Chapter X] ... section[@title[Section Y]@id[sec-y] ... section[@title[Another section] ...]]]"
		interpret text
		doc = @p.document
		doc.output.gsub(/\n|\t/, '').should == %{<div class="chapter">
					<h2 id="h_1">Chapter X</h2>... 
					<div class="section">
					<h3 id="sec-y">Section Y</h3>... 
						<div class="section">
						<h4 id="h_3">Another section</h4>...
						</div>
					</div>
				</div>
		}.gsub(/\n|\t/, '')
		doc.bookmark?(:"sec-y").should == {:id => :"sec-y", :title => "Section Y"} 
	end

	it "document, head, style" do
		interpret "document[head[style[test.sass]]]"
		@p.document.output.gsub(/\n|\t/, '').should == %{
		<?xml version="1.0" encoding="utf-8"?>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
			<head>
				<title>#{Glyph::CONFIG.get("document.title")}</title>
				<meta name="author" content="#{Glyph["document.author"]}" />
				<meta name="copyright" content="#{Glyph["document.author"]}" />
				<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
				<style type=\"text/css\">#main {  background-color: blue; }</style>
			</head>
		</html>
		}.gsub(/\n|\t/, '')
	end	

	it "style should link files by absolute or relative path in Lite mode" do
		result = %{
		<?xml version="1.0" encoding="utf-8"?>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
			<head>
				<title>#{Glyph::CONFIG.get("document.title")}</title>
				<meta name="author" content="#{Glyph["document.author"]}" />
				<meta name="copyright" content="#{Glyph["document.author"]}" />
				<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
				<style type=\"text/css\">#main {  background-color: blue; }</style>
			</head>
		</html>
		}.gsub(/\n|\t/, '')
		Glyph.lite_mode = true
		Dir.chdir Glyph::PROJECT
		interpret "document[head[style[styles/test.sass]]]"
		@p.document.output.gsub(/\n|\t/, '').should == result
		interpret "document[head[style[#{Glyph::PROJECT}/styles/test.sass]]]"
		@p.document.output.gsub(/\n|\t/, '').should == result
	end

	it "toc" do
		file_copy Glyph::PROJECT/'../files/document_with_toc.glyph', Glyph::PROJECT/'document.glyph'
		interpret file_load(Glyph::PROJECT/'document.glyph')
		doc = @p.document
		doc.output.gsub!(/\n|\t/, '')
		doc.output.slice(/(.+?<\/div>)/, 1).should == %{
			<div class="contents">
			<h2 class="toc-header" id="h_toc">Table of Contents</h2>
			<ol class="toc">
				<li class=" section"><a href="#h_1">Container section</a></li>
				<li class=" section"><a href="#md">Markdown</a></li>
			</ol>
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

	it "image" do
		interpret "image[@width[90%]@height[90%]@alt[-]ligature.jpg]"
		@p.document.output.gsub(/\t|\n/, '').should == %{
			<img src="images/ligature.jpg" width="90%" height="90%" alt="-" />
		}.gsub(/\n|\t/, '')
	end

	it "image should link files by absolute or relative path in Lite mode" do
		result = %{
			<img src="images/ligature.jpg" width="90%" height="90%" />
		}.gsub(/\n|\t/, '')
		Glyph.lite_mode = true
		Dir.chdir Glyph::PROJECT
		interpret "image[@width[90%]@height[90%]images/ligature.jpg]"
		@p.document.output.gsub(/\t|\n/, '').should == result
		interpret "image[@width[90%]@height[90%]#{Glyph::PROJECT}/images/ligature.jpg]"
		@p.document.output.gsub(/\t|\n/, '').gsub(Glyph::PROJECT.to_s+'/', '').should == result
	end

	it "figure" do
		interpret "figure[@alt[ligature]ligature.jpg|Ligature]"
		@p.document.output.gsub(/\t|\n/, '').should == %{
			<div class="figure">
			<img src="images/ligature.jpg" alt="ligature" />
			<div class="caption">Ligature</div>
			</div>
		}.gsub(/\n|\t/, '')
	end

	it "fig should link files by absolute or relative path in Lite mode" do
		result = %{
			<div class="figure">
			<img src="images/ligature.jpg" />
			<div class="caption">Ligature</div>
			</div>
		}.gsub(/\n|\t/, '')
		Glyph.lite_mode = true
		Dir.chdir Glyph::PROJECT
		interpret "figure[images/ligature.jpg|Ligature]"
		@p.document.output.gsub(/\t|\n/, '').should == result
		interpret "figure[#{Glyph::PROJECT}/images/ligature.jpg|Ligature]"
		@p.document.output.gsub(/\t|\n/, '').gsub(Glyph::PROJECT.to_s+'/', '').should == result
	end

	it "draftcomment, todo" do
		text1 = "dc[comment!]"
		text2 = "![todo!]"
		interpret text1
		@p.document.output.should == ""
		interpret text2
		@p.document.output.should == ""
		Glyph['document.draft'] = true
		interpret text1
		@p.document.output.should == %{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>comment!</span>}
		interpret text2
		@p.document.output.should == %{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>todo!</span>}
		@p.document.todos.length.should == 1
		Glyph['document.draft'] = false
	end

end	
