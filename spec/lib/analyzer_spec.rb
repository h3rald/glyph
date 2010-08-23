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
		lambda { Glyph::Analyzer.new(Glyph.document) }.should_not raise_error
		lambda { Glyph::Analyzer.new }.should_not raise_error
	end

	it "should expose a macro node iterator" do
		lambda { @a.with_macros }.should raise_error(ArgumentError, "No block given")
		count = 0
		lambda { @a.with_macros {|n| count+=1} }.should_not raise_error
		count.should == 20
		count = 0
		lambda { @a.with_macros(:snippet) {|n| count+=1} }.should_not raise_error
		count.should == 2
		count = 0
		lambda { @a.with_macros(:&) {|n| count+=1} }.should_not raise_error
		count.should == 2
	end

	it "should access macro instance arrays by definition" do
		@a.macro_array_for(:snippet).should == []
		@a.with_macros {}
		@a.macro_array_for(:snippet).length.should == 2
		@a.macro_array_for(:&).length.should == 2
		@a.macro_array_for(:section).length.should == 4
	end

	it "should raise an error if a stat is not available" do
		lambda { @a.stats_for :unknown }.should raise_error(RuntimeError, "Unable to calculate unknown stats")
	end

	it "should calculate stats for all macros" do
		lambda {@a.stats_for :macros}.should_not raise_error
		@a.stats[:macros].blank?.should == false
		c = @a.stats[:macros]
		c[:definitions].should == (Glyph::MACROS.keys - Glyph::ALIASES[:by_alias].keys).uniq.sort
		c[:aliases].should == Glyph::ALIASES[:by_alias].keys.sort
		c[:instances].length.should == 20
		c[:used_definitions].should == [:anchor, :include, :link, :markdown, :section, :snippet, :"snippet:", :textile, :toc]
	end

	it "should calculate stats for a single macro" do
		lambda {@a.stats_for :macro, :dsfash }.should raise_error(ArgumentError, "Unknown macro 'dsfash'")
		lambda {@a.stats_for :macro, :frontmatter }.should 
		raise_error(ArgumentError, "Alias 'frontmatter' is not used in this document, did you mean 'section'?")
		lambda {@a.stats_for :macro, :section }.should_not raise_error
		c = @a.stats[:macro]
		c[:instances].length.should == 4
		c[:files].should == [["document.glyph", 1], ["text/a/b/c/included.textile", 1], 
			["text/a/b/c/markdown.markdown", 1], ["text/container.textile", 1]]
		@a.stats_for :macro, :"&"
		c = @a.stats[:macro]
		c[:alias_for].should == :snippet
		c[:instances].length.should == 2
	end

	it "should calculate stats for all bookmarks" do
		lambda {@a.stats_for :bookmarks}.should_not raise_error
		c = @a.stats[:bookmarks]
		c[:codes].should == [:h_1, :h_2, :md, :refs, :toc, :unused]
		c[:unreferenced].should == [:h_2, :md, :toc, :unused]
		c[:referenced].should == [[:h_1, 1], [:refs, 1]]
	end

	it "should calculate stats for a single bookmark" do
		lambda {@a.stats_for :bookmark, '#h_7'}.should raise_error(ArgumentError, "Bookmark 'h_7' does not exist")
		lambda {@a.stats_for :bookmark, '#h_1'}.should_not raise_error
		c = @a.stats[:bookmark]
		c[:file].should == "text/container.textile"
		c[:references].should == [["text/references.glyph", 1]]
		c[:type].should == :header
	end

	it "should calculate stats for all links do" do
		lambda {@a.stats_for :links}.should_not raise_error
		c = @a.stats[:links]
		c[:internal].should == [["#h_1", {:total=>1, :files=>[["text/references.glyph", 1]]}], 
			 ["#refs", {:total=>1, :files=>[["text/references.glyph", 1]]}]]
		c[:external].should == [["http://www.h3rald.com", {:total=>1, :files=>[["text/references.glyph", 1]]}]]
	end

	it "should calculate stats for a single link" do
		lambda {@a.stats_for :link, 'q'}.should raise_error(ArgumentError, "No link matching /q/ was found")
		lambda {@a.stats_for :link, 'h'}.should_not raise_error
		c = @a.stats[:link][:stats]
		c.should == [["#h_1", {:total=>1, :files=>[["text/references.glyph", 1]]}], 
			["http://www.h3rald.com",{:total=>1, :files=>[["text/references.glyph", 1]]}]]
	end

	it "should calculate stats for all snippets" do
		lambda {@a.stats_for :snippets}.should_not raise_error
		c = @a.stats[:snippets]
		c[:used].should == [:test]
		c[:total].should == 2
		c[:unused].should == [:unused]
	 	c[:definitions].should == [:test, :unused]	
	end

	it "should calculate stats for a single snippet" do
		lambda {@a.stats_for :snippet, 'test1'}.should raise_error(ArgumentError, "Snippet 'test1' does not exist")
		lambda {@a.stats_for :snippet, 'unused'}.should raise_error(ArgumentError, "Snippet 'unused' is not used in this document")
		lambda {@a.stats_for :snippet, 'test'}.should_not raise_error
		c = @a.stats[:snippet][:stats]
		c.should == {:total=>2, :files=>[["document.glyph", 1], ["text/references.glyph", 1]]}
	end

	it "should calculate global stats" do
		lambda {@a.stats_for :global}.should_not raise_error
		c = @a.stats
		c[:bookmarks].blank?.should == false
		c[:links].blank?.should == false
		c[:snippets].blank?.should == false
		c[:macros].blank?.should == false
		c[:files].should == {:layouts=>0, :images=>1, :styles=>1, :text=>4, :lib=>0}
	end

end
