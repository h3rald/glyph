#!/usr/bin/env ruby
# encoding: UTF-8
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
		expect(doc.output).to eq("this is a <a id=\"test\">test</a>.")
		expect(doc.bookmarks[:test]).to eq(Glyph::Bookmark.new({:file => nil, :title => 'test', :id => :test}))
		expect { interpret "this is a #[test|test]. #[test|This won't work!]"; @p.document }.to raise_error
	end

	it "section, chapter, header" do
		text = "chapter[@title[Chapter X] ... section[@title[Section Y]@id[sec-y] ... section[@title[Another section] ...]]]"
		interpret text
		doc = @p.document
		expect(doc.output.gsub(/\n|\t/, '')).to eq(%{<div class="chapter">
					<h2 id="h_1" class="toc">Chapter X</h2>... 
					<div class="section">
					<h3 id="sec-y" class="toc">Section Y</h3>... 
						<div class="section">
						<h4 id="h_3" class="toc">Another section</h4>...
						</div>
					</div>
				</div>
		}.gsub(/\n|\t/, ''))
		expect(doc.bookmark?(:"sec-y")).to eq(Glyph::Bookmark.new({:id => :"sec-y", :title => "Section Y", :file => nil}))
	end

	it "document, head, style" do
		file_copy Glyph::SPEC_DIR/'files/test.scss', Glyph::PROJECT/'styles/test.scss'
		doc = %{
		<?xml version="1.0" encoding="utf-8"?>
		<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
		<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
			<head>
				<title>#{Glyph::CONFIG.get("document.title")}</title>
				<meta name="author" content="#{Glyph["document.author"]}" />
				<meta name="copyright" content="#{Glyph["document.author"]}" />
				<meta name="generator" content="Glyph v#{Glyph::VERSION} (http://www.h3rald.com/glyph)" />
				<meta http-equiv="content-type" content="text/html; charset=utf-8" />
				<style type=\"text/css\">#main {  background-color: #0000ff;  margin: 12px; }</style>
			</head>
		</html>
		}
		interpret "document[head[style[test.sass]]]"
		expect(@p.document.output.gsub(/\n|\t/, '')).to eq(doc.gsub(/\n|\t/, ''))
		interpret "document[head[style[test.scss]]]"
		expect(@p.document.output.gsub(/\n|\t/, '')).to eq(doc.gsub(/\n|\t/, ''))
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
				<meta http-equiv="content-type" content="text/html; charset=utf-8" />
				<style type=\"text/css\">#main {  background-color: #0000ff;  margin: 12px; }</style>
			</head>
		</html>
		}.gsub(/\n|\t/, '')
		Glyph.lite_mode = true
		Dir.chdir Glyph::PROJECT
		interpret "document[head[style[styles/test.sass]]]"
		expect(@p.document.output.gsub(/\n|\t/, '')).to eq(result)
	end

	it "style should import and link stylesheets" do
		Glyph['document.styles'] = 'import'
		expect(output_for("head[style[default.css]]").match(/@import url\("styles\/default\.css"\)/).blank?).to eq(false)
		Glyph['document.styles'] = 'link'
		expect(output_for("head[style[default.css]]").match(%{<link href="styles/default.css" rel="stylesheet" type="text/css" />}).blank?).to eq(false)
		Glyph['document.styles'] = 'embed'
	end

	it "toc" do
		file_copy Glyph::PROJECT/'../files/document_with_toc.glyph', Glyph::PROJECT/'document.glyph'
		interpret file_load(Glyph::PROJECT/'document.glyph')
		doc = @p.document
		doc.output.gsub!(/\n|\t/, '')
		expect(doc.output.slice(/(.+?<\/div>)/, 1)).to eq(%{
			<div class="contents">
			<h2 class="toc-header" id="toc">Table of Contents</h2>
			<ol class="toc">
				<li class="section"><a href="#h_1">Container section</a></li>
				<li class="section"><a href="#md">Markdown</a></li>
			</ol>
			</div>
		}.gsub(/\n|\t/, ''))
	end

	it "link" do
		text = %{
			link[#test_id]
			link[#test_id2]
			#[test_id|Test #1]
			#[test_id2|Test #2]
		}
		interpret text
		expect(@p.document.output.gsub(/\n|\t/, '')).to eq(%{
			<a href="#test_id">Test #1</a>
			<a href="#test_id2">Test #2</a>
			<a id="test_id">Test #1</a>
			<a id="test_id2">Test #2</a>
		}.gsub(/\n|\t/, ''))
	end

	it "fmi" do
		interpret "fmi[this topic|#test] #[test|Test]"
		expect(@p.document.output).to eq(%{<span class="fmi">
			for more information on this topic, 
			see <a href="#test">Test</a></span> <a id="test">Test</a>}.gsub(/\n|\t/, ''))
	end	

	it "image" do
		interpret "image[@width[90%]@height[90%]@alt[-]ligature.jpg]"
		expect(@p.document.output.gsub(/\t|\n/, '')).to eq(%{
			<img src="images/ligature.jpg" width="90%" height="90%" alt="-" />
		}.gsub(/\n|\t/, ''))
	end

	it "image should link files by absolute or relative path in Lite mode" do
		result = %{
			<img src="images/ligature.jpg" width="90%" height="90%" />
		}.gsub(/\n|\t/, '')
		Glyph.lite_mode = true
		Dir.chdir Glyph::PROJECT
		interpret "image[@width[90%]@height[90%]images/ligature.jpg]"
		expect(@p.document.output.gsub(/\t|\n/, '')).to eq(result)
		interpret "image[@width[90%]@height[90%]#{Glyph::PROJECT}/images/ligature.jpg]"
		expect(@p.document.output.gsub(/\t|\n/, '').gsub(Glyph::PROJECT.to_s+'/', '')).to eq(result)
	end

	it "figure" do
		interpret "figure[@alt[ligature]ligature.jpg|Ligature]"
		expect(@p.document.output.gsub(/\t|\n/, '')).to eq(%{
			<div class=\"figure\" alt=\"ligature\">
				<img src=\"images/ligature.jpg\" />
				<div class=\"caption\">Ligature</div>
			</div>}.gsub(/\n|\t/, ''))
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
		expect(@p.document.output.gsub(/\t|\n/, '')).to eq(result)
		interpret "figure[#{Glyph::PROJECT}/images/ligature.jpg|Ligature]"
		expect(@p.document.output.gsub(/\t|\n/, '').gsub(Glyph::PROJECT.to_s+'/', '')).to eq(result)
	end

	it "draftcomment, todo" do
		text1 = "dc[comment!]"
		text2 = "![todo!]"
		interpret text1
		expect(@p.document.output).to eq("")
		interpret text2
		expect(@p.document.output).to eq("")
		Glyph['document.draft'] = true
		interpret text1
		expect(@p.document.output).to eq(%{<span class="comment"><span class="comment-pre"><strong>Comment:</strong> </span>comment!</span>})
		interpret text2
		expect(@p.document.output).to eq(%{<span class="todo"><span class="todo-pre"><strong>TODO:</strong> </span>todo!</span>})
		expect(@p.document.todos.length).to eq(1)
		Glyph['document.draft'] = false
	end

  it "Aliased section titles should be at the same level of non-aliased section titles" do
    normal = %{
      section[
        @title[Title2]
        ...
      ]
    }
    aliased = %{
      §[
        @title[Title2]
        ...
      ]
    }
    container = lambda do |s|
      %{
      section[
        @title[Title]
        #{s}
      ]
      }
    end
    expect(output_for(container.call aliased)).to eq(output_for(container.call normal))
  end

end	
