#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::SyntaxNode do

	it "should evaluate"

	it "should return its parent macro"

	it "should convert to a string implicitly" do
		"#{text_node("test")}".should == "test"
		"#{escape_node("\\.")}".should == "\\."
		"#{document_node}".should == ""
		p0 = p_node(0)
		p0 << text_node("p0")
		p1 = p_node(1)
		p1 << text_node("p1")
		"#{p0}".should == "p0"
		"#{p1}".should == "p1"
		a = a_node(:a)
		a << text_node("a")
		b = a_node(:b)
		b << text_node("b")
		"#{a}".should == "@a[a]"
		"#{b}".should == "@b[b]"
		m = macro_node(:test, :escape => true)
		m << a
		m << b
		m << p0
		m << p1
		"#{m}".should == "test[=@a[a]@b[b]p0|p1=]"
	end

end

describe Glyph::MacroNode do

	it "should expand the corresponding macro"

	it "should resolve to an XML element"

	it "should retrieve parameter nodes easily"

	it "should retrieve attribute nodes easily"
	
end
