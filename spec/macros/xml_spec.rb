#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Glyph Language" do

	before do
		create_project
	end

	after do
		Glyph.lite_mode = false
		Glyph['language.set'] = 'glyph'
		delete_project
	end

	it "should support XML fallback by default" do
		Glyph.run 'load:all'
		output_for(%{
			i[test]
			code[
			test
			]
		}).gsub(/\s+/, '').should == %{
		<i>test</i>
		<div class="code">
			<pre>
				<code>
					test
				</code>
				</pre>
		</div>}.gsub(/\s+/, '')
		output_for(%{
			=code[test...]
		}).gsub(/\s/, '').should == %{<code>test...</code>}
	end

	it "should support XML macros" do
		language('xml')
		output_for("pre[code[test]]").should == "<pre><code>test</code></pre>"
	end

	it "should support XML attributes" do
		language('xml')
		output_for("span[@class[test] @style[color:red;] test...]").should == %{
			<span class="test" style="color:red;">test...</span>
		}.strip
	end

	it "should detect invalid characters for XML elements and attributes" do
		language('xml')
		interpret("!&test[test]").should raise_error
		output_for("span[@class[test]@.[test]test]").should == %{<span class="test">test</span>}
	end

	it "should assign default attribute names to parameters passed by position" do
		language('xml')
		output_for("test[a|b|@class[test] test]").should == %{<test class="test" p1="a" p2="b">test</test>}
	end

end	
