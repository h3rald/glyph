#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Glyph Language" do

	before do
		create_project
	end

	after do
		reset_quiet
		language('glyph')
		delete_project
	end

	it "should support XML fallback by default" do
		Glyph.run 'load:all'
		expect(output_for(%{
			i[test]
			code[
			test
			]
		}).gsub(/\s+/, '')).to eq(%{
		<i>test</i>
				<code>
					test
				</code>}.gsub(/\s+/, ''))
	end

	it "should support XML macros" do
		language('xml')
		expect(output_for("pre[code[test]]")).to eq("<pre>\n<code>test</code>\n</pre>")
	end

	it "should support XML attributes" do
		language('xml')
		expect(output_for("span[@class[test] @style[color:red;] test...]")).to eq(%{
			<span class="test" style="color:red;">  test...</span>
		}.strip)
	end

	it "should detect invalid characters for XML elements and attributes" do
		language('xml')
		expect  { interpret("!&test[test]").document }.to raise_error
		expect(output_for("span[@class[test]@.[test]test]")).to eq(%{<span class="test">test</span>})
	end

	it "should notify the user that a macro is not found for invalid elements if xml_fallback is enabled" do
		# Assuming options.xml_fallback = true
		language('glyph')
		expect { interpret("*a[test]").document }.to raise_error(Glyph::MacroError, "Invalid XML element '*a'")
	end	

	it "should not render blacklisted tags" do
		language('xml')
		text = %{
			object[test]
			applet[test]
      base[test]
      basefont[test]
      embed[test]
      frame[test]
      frameset[test]
      iframe[test]
      isindex[test]
			test[test]
      meta[test]
      noframes[test]
      noscript[test]
      object[test]
      param[test]
      title[tesy]
		}
		expect(output_for(text).gsub(/\s/, '')).to eq("<test>test</test>")
	end

	it "should work with macro composition" do
		language('glyph')
		expect(output_for("xml/a[@test[...]xyz]")).to eq("<a test=\"...\">xyz</a>")
		expect(output_for("xml/a[@test[...]xml/b[test]]")).to eq("<a test=\"...\">\n<b>test</b>\n</a>")
		expect(output_for("xml/a[xml/b[test]xml/c[test]]")).to eq("<a>\n<b>test</b><c>test</c>\n</a>")
		expect(output_for("xml/a[xml/b[test]xml/c[@test[test_attr]test]]")).to eq("<a>\n<b>test</b><c test=\"test_attr\">test</c>\n</a>")
		expect(output_for("xml/a[xml/b[@test[true]]]")).to eq("<a>\n<b test=\"true\" />\n</a>")
	end

end	
