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

	def stats(name, *args)
		@a.stats_for(name, *args)
	end
	
	def rep
		@r = Glyph::Reporter.new(@a.stats)
	end

	after do
		delete_project_dir
	end

	it "should be initialized with stats" do
		stats :macros
		lambda { rep }.should_not raise_error
	end

	it "should display macro stats" do
		stats :macros
		out = stdout_for { rep.display }
		out.should match "Total Macro Instances: 20"
		out.should match "-- Used Macro Definitions: anchor, include, link, markdown, section, snippet, snippet:, textile, toc"
		@r.detailed = false
		out = stdout_for { @r.display }
		out.should_not match "-- Used Macro Definitions: anchor, include, link, markdown, section, snippet, snippet:, textile, toc"
	end

	it "should display stats for a single macro" do
		stats :macro, :section
		out = stdout_for { rep.display }
		out.should match "text/a/b/c/markdown.markdown \\(1\\)"
		out.should match "-- Total Instances: 4"
		@r.detailed = false
		out = stdout_for { @r.display }
		out.should_not match "text/a/b/c/markdown.markdown \\(1\\)"
		stats :macro, :"=>"
		out = stdout_for { rep.display }
		out.should match "alias for: link"
	end

	it "should display bookmark stats"

	it "should display stats for a single bookmark"

	it "should display snippet stats"

	it "should display stats for a single snippet"

	it "should display link stats"

	it "should display stats for a single link"

	it "should display files stats"

	it "should display global stats"

	

end
