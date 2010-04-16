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
</div>}
		@html = 
%{<p>This is a <em>test</em>:</p>
<ul>
	<li>item A</li>
	<li>item B</li>
	<li>item C</li>
</ul>
<div class="test"><em>hello!</em></div>}
		create_project
		Glyph.run! 'load:macros'
		Glyph.run! 'load:snippets'
	end

	after do
		delete_project
	end

	######################################
	
	it "should be embeddable in section macros" do
		text = 
%{textile[section[header[Test]
#@textile
]]}
		result =
%{<div class="section">
<h2 id="h_1">Test</h2>
#@html
</div>}
		filter(text).should == result
	end


	######################################
	
	it "should be embeddable in td macros" do
		text0 =
%{<table>
<tr>
<td>
#@textile
</td>
</tr>
</table>
}
		text1 =
%{textile[table[
	tr[td[#@textile]]
]]}
		text2 =
%{textile[table[
	tr[
		td[#@textile]
	]
]]}
		text3 =
%{textile[table[
	tr[
		td[
#@textile
		]
	]
]]}
		result = 
%{<table>
<tr>
<td>
#@html
</td>
</tr>
</table>}
		RedCloth.new(text0).to_html.should == result
		filter(text1).should == result
		filter(text2).should == result
		filter(text3).should == result
	end

	

end	
