#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe "Textile Markup" do

	before do
		@textile = 
%{This is a _test_:
* item A
* item B
* item C

<div class="test">_hello!_
</div>
Testing:
# A
# B
# C}
		@html = 
%{<p>This is a <em>test</em>:</p>
<ul>
	<li>item A</li>
	<li>item B</li>
	<li>item C</li>
</ul>
<div class="test"><em>hello!</em></div>
<p>Testing:</p>
<ol>
	<li>A</li>
	<li>B</li>
	<li>C</li>
</ol>}
	end

	######################################
	
	it "should be embeddable in section macros" do
		text1 = 
%{textile[section[@title[Test]
#@textile
]]}
		text2 = 
%{textile[section[@title[Test]#@textile
]]}
		result =
%{<div class="section">
<h2 id="h_1" class="toc">Test</h2>
#@html
</div>}
		expect(filter(text1)).to eq(result)
		expect(filter(text2).gsub(/<\/h2>/, "</h2>")).to eq(result)
	end

	######################################

	it "should be embeddable in box macros" do
		result = 
%{<div class="box">
<div class="box-title">This is a <em>test</em></div>
#@html
</div>}
		box1 = %{textile[box[This is a _test_|#@textile]]}
		box2 = %{textile[box[This is a _test_|
#@textile]
]}
		box3 = %{textile[box[
		This is a _test_|
			#@textile]]}
		box4 =  %{textile[box[This is a _test_|
#@textile
	]
]}
		expect(filter(box1)).to eq(result)
		expect(filter(box2)).to eq(result)
		expect(filter(box3)).to eq(result)
		expect(filter(box4)).to eq(result)
	end
	
	######################################

	it "should be embeddable in note macros" do
				result = 
%{<div class="note">
<p><span class="note-title">Note</span>#{@html.sub(/^<p>/, '')}
</div>}
		note1 = %{textile[note[#@textile]]}
		note2 = %{textile[note[
#@textile]
]}
		note3 = %{textile[note[
			#@textile]]}
		note4 =  %{textile[note[
#@textile
	]
]}
		expect(filter(note1)).to eq(result)
		expect(filter(note2)).to eq(result)
		expect(filter(note3)).to eq(result)
		expect(filter(note4)).to eq(result)
	end
	
	######################################
	
	it "should not interfere with the code macro" do
		code = 
%{<div class="test">
<p><em>Test: </em> Paragraph.</p>
</div>}
		result = 
%{<div class="section">
<h2 id="h_1" class="toc">Test</h2>
#@html
<div class="code">
<pre>
<code>
#{code.gsub(/>/, '&gt;').gsub(/</, '&lt;')}
</code>
</pre>
</div>
</div>}
		text1 = %{textile[
			section[@title[Test]
#@textile
			codeblock[#{code}]
]]}
		text2 = %{textile[
			section[@title[Test]
#@textile
			codeblock[#{code}
		]
	]
]}
		text3 = %{textile[
			section[@title[Test]
#@textile
			codeblock[
#{code}]
]]}
		text4 = %{textile[
			section[@title[Test]
#@textile
			codeblock[
#{code}
]]]}
		text5 = %{textile[
			section[@title[Test]
#@textile
			codeblock[
#{code}
	]
	]]}
		expect(filter(text1)).to eq(result)
		expect(filter(text2)).to eq(result)
		expect(filter(text3)).to eq(result)
		expect(filter(text4)).to eq(result)
		expect(filter(text5)).to eq(result)
	end

end	
