#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Macro:" do

	before do
		reset_quiet
		create_project
		Glyph['document.output'] = 'html5'
		Glyph.run! 'load:all'
	end

	after do
		Glyph.lite_mode = false
		reset_quiet
		delete_project
	end

	it "section, chapter, header (html5)" do
		text = "chapter[@title[Chapter X] ... section[@title[Section Y]@id[sec-y] ... section[@title[Another section] ...]]]"
		interpret text
		doc = @p.document
		doc.output.gsub(/\n|\t/, '').should == %{<section class="chapter">
					<header><h1 id="h_1">Chapter X</h1></header>... 
					<section class="section">
					<header><h1 id="sec-y">Section Y</h1></header>... 
						<section class="section">
						<header><h1 id="h_3">Another section</h1></header>...
						</section>
					</section>
				</section>
		}.gsub(/\n|\t/, '')
		doc.bookmark?(:"sec-y").should == Glyph::Bookmark.new({:id => :"sec-y", :title => "Section Y", :file => nil})
	end

	it "document, head, style (html5)" do
		interpret "document[head[style[test.sass]]]"
		@p.document.output.gsub(/\n|\t/, '').should == %{
		<!DOCTYPE html>
		<html lang="en">
			<head>
				<title>#{Glyph::CONFIG.get("document.title")}</title>
				<meta name="author" content="#{Glyph["document.author"]}" />
				<meta name="copyright" content="#{Glyph["document.author"]}" />
				<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
				<meta http-equiv="content-type" content="text/html; charset=utf-8" />
				<style type=\"text/css\">#main {  background-color: blue;  margin: 12px; }</style>
			</head>
		</html>
		}.gsub(/\n|\t/, '')
	end	

	it "toc (html5)" do
		file_copy Glyph::PROJECT/'../files/document_with_toc.glyph', Glyph::PROJECT/'document.glyph'
		interpret file_load(Glyph::PROJECT/'document.glyph')
		doc = @p.document
		doc.output.gsub!(/\n|\t/, '')
		doc.output.slice(/(.+?<\/nav>)/, 1).should == %{
			<nav class="contents">
			<h1 class="toc-header" id="toc">Table of Contents</h1>
			<ol class="toc">
				<li class="section"><a href="#h_1">Container section</a></li>
				<li class="section"><a href="#md">Markdown</a></li>
			</ol>
			</nav>
		}.gsub(/\n|\t/, '')
	end

	it "fmi (html5)" do
		interpret "fmi[this topic|#test] #[test|Test]"
		@p.document.output.should == %{<span class="fmi">
			for more information on <mark>this topic</mark>, 
			see <a href="#test">Test</a></span> <a id="test">Test</a>}.gsub(/\n|\t/, '')
	end	

	it "figure (html5)" do
		interpret "figure[@alt[ligature]ligature.jpg|Ligature]"
		@p.document.output.gsub(/\t|\n/, '').should == %{
			<figure alt=\"ligature\">
				<img src=\"images/ligature.jpg\" />
				<figcaption>Ligature</figcaption>
			</figure>}.gsub(/\n|\t/, '')
	end

	it "draftcomment, todo (html5)" do
		text1 = "dc[comment!]"
		text2 = "![todo!]"
		interpret text1
		@p.document.output.should == ""
		interpret text2
		@p.document.output.should == ""
		Glyph['document.draft'] = true
		interpret text1
		@p.document.output.should == %{<aside class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>comment!</aside>}
		interpret text2
		@p.document.output.should == %{<aside class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>todo!</aside>}
		@p.document.todos.length.should == 1
		Glyph['document.draft'] = false
	end
end	
