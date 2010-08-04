require 'rubygems'
require 'pathname'
require 'extlib'
require 'bluecloth'
require 'redcloth'
require 'benchmark'
require Pathname.new(__FILE__).parent/"lib/glyph.rb"



def macro_exec(text)
	Glyph::Interpreter.new(text).document.output
end

def sep
	puts "="*100
end

N = 50

def rep(x, title, &block)
	x.report(title.to_s) { N.times(&block) }
end

def reset_glyph
	Glyph.lite_mode = true
	Glyph['system.quiet'] = true
end


text = %{
Lorem ipsum dolor sit amet, consectetur _adipisicing elit_, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
* Duis aute irure dolor in *reprehenderit* in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
* Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
}
html = %{
p[Lorem ipsum dolor sit amet, consectetur em[adipisicing elit], sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.]
p[Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.]
ul[
	li[Duis aute irure dolor in strong[reprehenderit] in voluptate velit esse cillum dolore eu fugiat nulla pariatur.]
	li[Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.]
]
}

reset_glyph
Glyph.run! 'load:all'
Glyph::SNIPPETS[:test] = text
Benchmark.bm(30) do |x|

	sep
	puts " => Core Classes"
	rep(x, "Glyph::Interpreter.new.parse") {Glyph::Interpreter.new(text).parse}
	rep(x, "Glyph::Parser.new(text).parse") {Glyph::Parser.new(text).parse}
	sep
	puts " => Macro Set: Glyph"
	sep
	rep(x, "section[...]") { macro_exec "section[#{text}]" }
	rep(x, "snippet[...]") { macro_exec "snippet[test]" }
  rep(x, "textile[...]") { macro_exec "textile[#{text}]" }
	rep(x, "markdown[...]") { macro_exec "markdown[#{text}]" }
	rep(x, "HTML text") { macro_exec html }
	sep
	rep(x, "Markdown (BlueCloth)") {BlueCloth.new(text).to_html } 
	rep(x, "Textile (RedCloth)") {RedCloth.new(text).to_html } 
	sep
	puts " => Macro Set: XML"
	reset_glyph
	Glyph['options.macro_set'] = 'xml'
	Glyph.run! 'load:all'
	rep(x, "HTML text") { macro_exec html }
end
