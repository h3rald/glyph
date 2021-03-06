#!/usr/bin/env ruby
# encoding: utf-8

describe "Filter Macros" do

	before do
		delete_project
		create_project
		Glyph.run! 'load:macros'
	end

	after do
		delete_project
	end

	it "should filter textile input" do
		text = "textile[This is a _TEST_(TM).]"
		interpret text
		expect(@p.document.output).to eq("<p>This is a <em><span class=\"caps\">TEST</span></em>&#8482;.</p>")
		Glyph["output.#{Glyph['document.output']}.filter_target"] = :latex
		interpret text
		expect(@p.document.output).to eq("This is a \\emph{TEST}\\texttrademark{}.\n\n")
		Glyph["output.#{Glyph['document.output']}.filter_target"] = :html
		Glyph['filters.redcloth.restrictions'] = [:no_span_caps]
		interpret text
		expect(@p.document.output).to eq("<p>This is a <em>TEST</em>&#8482;.</p>")
	end

	it "should filter markdown input" do
		text = "markdown[This is a test:

- item 1
- item 2
- item 3

etc.]"
interpret text
expect(@p.document.output.gsub(/\n|\t|\s{2}/, '')).to eq( 
	"<p>This is a test:</p><ul><li>item 1</li><li>item 2</li><li>item 3</li></ul><p>etc.</p>"
)
	end

	it "highlight" do
		cr = false
		uv = false
		begin
			require 'coderay'
			cr = true
		rescue Exception
		end
		begin
			require 'uv'
			uv = true
		rescue Exception
		end
		code = %{def test_method(a, b)
				puts a+b
			end}
			cr_result = %{<div class=\"CodeRay\"> <div class=\"code\"><pre><span class=\"line-numbers\"><a href=\"#n1\" name=\"n1\">1</a></span><span class=\"keyword\">def</span> <span class=\"function\">test_method</span>(a, b) <span class=\"line-numbers\"><a href=\"#n2\" name=\"n2\">2</a></span> puts a+b <span class=\"line-numbers\"><a href=\"#n3\" name=\"n3\">3</a></span> <span class=\"keyword\">end</span></pre></div> </div>}
			uv_result = %{<pre class=\"iplastic\"><span class=\"Keyword\">def</span> 
			<span class=\"FunctionName\">test_method</span>(<span class=\"Arguments\">a<span class=\"Arguments\">,</span> b</span>) 
			puts a<span class=\"Keyword\">+</span>b <span class=\"Keyword\">end</span></pre>}
			Glyph['filters.ultraviolet.theme'] = 'iplastic'
			check = lambda do |hl, result|
				Glyph["filters.highlighter"] = hl.to_sym
				Glyph.debug_mode = true
				interpret("highlight[=ruby|\n#{code}=]")
				expect(@p.document.output.gsub(/\s+/, ' ').strip).to eq(result.gsub(/\s+/, ' ').strip)
			end
			Glyph['filters.ultraviolet.line_numbers'] = false
			check.call 'ultraviolet', uv_result if uv
			check.call 'coderay', cr_result if cr
	end

	it "textile_section, markdown_section" do
		expect(output_for("§txt[*test*]")).to eq("<div class=\"section\">\n<p><strong>test</strong></p>\n\n</div>")
		expect(output_for("§md[*test*]")).to eq("<div class=\"section\">\n<p><em>test</em></p>\n\n</div>")
		expect(output_for("textile_section[@title[test]...]")).to eq("<div class=\"section\">\n<h2 id=\"h_1\" class=\"toc\">test</h2>\n<p>&#8230;</p>\n\n</div>")
	end


end	
