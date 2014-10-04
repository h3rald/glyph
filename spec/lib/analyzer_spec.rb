# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Analyzer do

	before do
		reset_quiet
		create_project_dir
		create_project
		Glyph.file_copy Glyph::SPEC_DIR/'files/document_for_stats.glyph', Glyph::PROJECT/'document.glyph'
		Glyph.file_copy Glyph::SPEC_DIR/'files/references.glyph', Glyph::PROJECT/'text/references.glyph'
		Glyph.run! 'generate:document'
		@a = Glyph::Analyzer.new
	end

	after do
		delete_project_dir
	end

	it "should be initialized with a document" do
		expect { Glyph::Analyzer.new(Glyph.document) }.not_to raise_error
		expect { Glyph::Analyzer.new }.not_to raise_error
	end

	it "should expose a macro node iterator" do
		expect { @a.with_macros }.to raise_error(ArgumentError, "No block given")
		count = 0
		expect { @a.with_macros {|n| count+=1} }.not_to raise_error
		expect(count).to eq(20)
		count = 0
		expect { @a.with_macros(:snippet) {|n| count+=1} }.not_to raise_error
		expect(count).to eq(2)
		count = 0
		expect { @a.with_macros(:&) {|n| count+=1} }.not_to raise_error
		expect(count).to eq(2)
	end

	it "should access macro instance arrays by definition" do
		expect(@a.macro_array_for(:snippet)).to eq([])
		@a.with_macros {}
		expect(@a.macro_array_for(:snippet).length).to eq(2)
		expect(@a.macro_array_for(:&).length).to eq(2)
		expect(@a.macro_array_for(:section).length).to eq(4)
	end

	it "should raise an error if a stat is not available" do
		expect { @a.stats_for :unknown }.to raise_error(RuntimeError, "Unable to calculate unknown stats")
	end

	it "should calculate stats for all macros" do
		expect {@a.stats_for :macros}.not_to raise_error
		expect(@a.stats[:macros].blank?).to eq(false)
		c = @a.stats[:macros]
		expect(c[:definitions]).to eq((Glyph::MACROS.keys - Glyph::ALIASES[:by_alias].keys).uniq.sort)
		expect(c[:aliases]).to eq(Glyph::ALIASES[:by_alias].keys.sort)
		expect(c[:instances].length).to eq(20)
		expect(c[:used_definitions]).to eq([:anchor, :include, :link, :markdown, :section, :snippet, :"snippet:", :textile, :toc])
	end

	it "should calculate stats for a single macro" do
		expect {@a.stats_for :macro, :dsfash }.to raise_error(ArgumentError, "Unknown macro 'dsfash'")
		expect {@a.stats_for :macro, :frontmatter }.to raise_error(ArgumentError, "Macro 'frontmatter' is not used in this document, did you mean 'section'?")
		expect {@a.stats_for :macro, :section }.not_to raise_error
		c = @a.stats[:macro]
		expect(c[:instances].length).to eq(4)
		expect(c[:files]).to eq([["document.glyph", 1], ["text/a/b/c/included.textile", 1], 
			["text/a/b/c/markdown.markdown", 1], ["text/container.textile", 1]])
		@a.stats_for :macro, :"&"
		c = @a.stats[:macro]
		expect(c[:alias_for]).to eq(:snippet)
		expect(c[:instances].length).to eq(2)
	end

	it "should calculate stats for all bookmarks" do
		expect {@a.stats_for :bookmarks}.not_to raise_error
		c = @a.stats[:bookmarks]
		expect(c[:codes]).to eq([:h_1, :h_2, :md, :refs, :toc, :unused])
		expect(c[:unreferenced]).to eq([:h_2, :md, :toc, :unused])
		expect(c[:referenced]).to eq([[:h_1, 1], [:refs, 1]])
	end

	it "should calculate stats for a single bookmark" do
		expect {@a.stats_for :bookmark, '#h_7'}.to raise_error(ArgumentError, "Bookmark 'h_7' does not exist")
		expect {@a.stats_for :bookmark, '#h_1'}.not_to raise_error
		c = @a.stats[:bookmark]
		expect(c[:file]).to eq("text/container.textile")
		expect(c[:references]).to eq([["text/references.glyph", 1]])
		expect(c[:type]).to eq(:header)
	end

	it "should calculate stats for all links do" do
		expect {@a.stats_for :links}.not_to raise_error
		c = @a.stats[:links]
		expect(c[:internal]).to eq([["#h_1", {:total=>1, :files=>[["text/references.glyph", 1]]}], 
			 ["#refs", {:total=>1, :files=>[["text/references.glyph", 1]]}]])
		expect(c[:external]).to eq([["http://www.h3rald.com", {:total=>1, :files=>[["text/references.glyph", 1]]}]])
	end

	it "should calculate stats for a single link" do
		expect {@a.stats_for :link, 'q'}.to raise_error(ArgumentError, "No link matching /q/ was found")
		expect {@a.stats_for :link, 'h'}.not_to raise_error
		c = @a.stats[:link][:stats]
		expect(c).to eq([["#h_1", {:total=>1, :files=>[["text/references.glyph", 1]]}], 
			["http://www.h3rald.com",{:total=>1, :files=>[["text/references.glyph", 1]]}]])
	end

	it "should calculate stats for all snippets" do
		expect {@a.stats_for :snippets}.not_to raise_error
		c = @a.stats[:snippets]
		expect(c[:used]).to eq([:test])
		expect(c[:total]).to eq(2)
		expect(c[:unused]).to eq([:unused])
	 	expect(c[:definitions]).to eq([:test, :unused])	
	end

	it "should calculate stats for a single snippet" do
		expect {@a.stats_for :snippet, 'test1'}.to raise_error(ArgumentError, "Snippet 'test1' does not exist")
		expect {@a.stats_for :snippet, 'unused'}.to raise_error(ArgumentError, "Snippet 'unused' is not used in this document")
		expect {@a.stats_for :snippet, 'test'}.not_to raise_error
		c = @a.stats[:snippet][:stats]
		expect(c).to eq({:total=>2, :files=>[["document.glyph", 1], ["text/references.glyph", 1]]})
	end

	it "should calculate global stats" do
		expect {@a.stats_for :global}.not_to raise_error
		c = @a.stats
		expect(c[:bookmarks].blank?).to eq(false)
		expect(c[:links].blank?).to eq(false)
		expect(c[:snippets].blank?).to eq(false)
		expect(c[:macros].blank?).to eq(false)
		expect(c[:files]).to eq({:layouts=>0, :images=>1, :styles=>1, :text=>4, :lib=>0})
	end

end
