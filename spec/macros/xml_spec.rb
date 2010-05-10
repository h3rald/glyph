#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Glyph Language" do

	before do
		create_project
	end

	after do
		Glyph.lite_mode = false
		Glyph['language.macros'] = 'glyph'
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
	end

	it "should support XML macros" do
		reset_quiet
		Glyph.run 'load:config'
		Glyph['language.macros'] = 'xml'
		Glyph.run 'load:macros'
		output_for("pre[code[test]]").should == "<pre><code>test</code></pre>"
	end

	it "should allow only common macros to be loaded" do
		reset_quiet
		Glyph.run 'load:config'
		Glyph['language.macros'] = nil
		Glyph['language.options.common_macros'] = true
		Glyph.run 'load:macros'
		output_for("--[test $:[language.macros|glyph]]").blank?.should == true
		Glyph['language.macros'].should == 'glyph'
	end

	it "should support XML attributes"

	it "should detect invalid characters for XML elements and attributes"

end	
