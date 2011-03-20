# encoding: utf-8

GLI.desc 'Display statistics'
command :stats do |c|
	c.desc "Display stats about macros"
	c.switch [:m, :macros]
	c.desc "Display stats about snippets"
	c.switch [:s, :snippets]
	c.desc "Display stats about bookmarks"
	c.switch [:b, :bookmarks]
	c.desc "Display stats about links"
	c.switch [:l, :links]
	c.desc "Display stats about project files"
	c.switch [:f, :files]
	c.desc "Display stats about a single macro"
	c.flag :macro
	c.desc "Display stats about a single bookmark"
	c.flag :bookmark
	c.desc "Display stats about links matching a regular expression"
	c.flag :link
	c.desc "Display stats about a single snippet"
	c.flag :snippet
	c.action do |global_options, options, args|
		Glyph.info "Collecting stats..."
		Glyph.run 'generate:document'
		analyzer = Glyph::Analyzer.new
		no_switches = true
		[[:m, :macros], [:s, :snippets], [:b, :bookmarks], [:l, :links], [:f, :files]].each do |s|
			if options[s[0]] then
				analyzer.stats_for s[1]
			 	no_switches = false
			end	
		end
		no_flags = true
		[:macro, :bookmark, :link, :snippet].each do |f|
			if options[f] then
				analyzer.stats_for :snippets if f == :snippet
				analyzer.stats_for f, options[f] 
				no_flags = false
			end
		end
		analyzer.stats_for :global if no_switches && no_flags 
		puts "====================================="
		puts "#{Glyph['document.title']} - Statistics"
		puts "====================================="
		puts
		reporter = Glyph::Reporter.new(analyzer.stats)
		reporter.detailed = false if no_switches && no_flags 
		reporter.display
	end
end
