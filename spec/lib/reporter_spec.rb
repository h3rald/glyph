# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Reporter do

	before do
		delete_project
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
		expect { rep }.not_to raise_error
	end

	it "should display macro stats" do
		stats :macros
		out = stdout_for { rep.display }
		expect(out).to match "Total Macro Instances: 20"
		expect(out).to match "-- Used Macro Definitions:"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "-- Used Macro Definitions:"
	end

	it "should display stats for a single macro" do
		stats :macro, :section
		out = stdout_for { rep.display }
		expect(out).to match "text/a/b/c/markdown.markdown \\(1\\)"
		expect(out).to match "-- Total Instances: 4"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "text/a/b/c/markdown.markdown \\(1\\)"
		stats :macro, :"=>"
		out = stdout_for { rep.display }
		expect(out).to match "alias for: link"
	end

	it "should display bookmark stats" do
		stats :bookmarks
		out = stdout_for { rep.display }
		expect(out).to match "-- Total Bookmarks: 6"
		expect(out).to match "h_1    h_2    md     refs   toc"
		expect(out).to match "   - h_1 \\(1\\)"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "-- Occurrences:"
	end

	it "should display stats for a single bookmark" do
		stats :bookmark, 'refs'
		out = stdout_for { rep.display }
		expect(out).to match "===== Bookmark 'refs' \\(header\\)"
		expect(out).to match "   - text/references.glyph \\(1\\)"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "-- Referenced in:"
	end

	it "should display snippet stats" do
		stats :snippets
		out = stdout_for { rep.display }
		expect(out).to match "-- Total Snippets: 2"
	end

	it "should display stats for a single snippet" do
		stats :snippets
		stats :snippet, :test
		out = stdout_for { rep.display }
		expect(out).to match "-- Total Used Instances: 2"
		expect(out).to match "   - text/references.glyph \\(1\\)"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "-- Usage Details:"
	end

	it "should display link stats" do
		stats :links
		out = stdout_for { rep.display }
		expect(out).to match "http://www.h3rald.com"
		expect(out).to match "-- Total Internal Links: 2"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "     - text/references.glyph (1)"
	end

	it "should display stats for a single link" do
		stats :link, 'h3'
		out = stdout_for { rep.display }
		expect(out).to match "===== Links matching \\/h3\\/"
		expect(out).to match "   - http://www.h3rald.com \\(1\\)"
		@r.detailed = false
		out = stdout_for { @r.display }
		expect(out).not_to match "   - http://www.h3rald.com \\(1\\)"
	end

	it "should display files stats" do
		stats :files
		out = stdout_for { rep.display }
		expect(out).to match "-- Total Files: 6"
		expect(out).to match "-- /text    -- 4"
	end

	it "should display global stats" do
		stats :global
		out = stdout_for { rep.display }
		expect(out).to match "-- Total Files: 6"
		expect(out).to match "   - http://www.h3rald.com"
		expect(out).to match "Total Macro Instances: 20"
		expect(out).to match "-- Total Snippets: 2"
		expect(out).to match "h_1    h_2    md     refs   toc"
	end
end
