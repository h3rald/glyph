#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::SyntaxNode do

	it "should evaluate" do
		t = text_node("test")
		t.evaluate({})
		t[:value].should == "test"
		e = escape_node("\\.")
		e.evaluate({})
		e[:value].should == "\\."
		p = p_node(0)
		a = a_node(:a)
		a << e
		p << t
		p.evaluate({}, :params => true)
		p[:value].should == "test"
		a.evaluate({}, :attrs => true)
		a[:value].should == "\\."
		Glyph.macro :test do
			attribute(:a)+param(0)
		end
		m = macro_node(:test)
		m << p
		m << a
		m.evaluate({})
		m[:value].should == "\\.test"
	end

	it "should return its parent macro" do
		node = Glyph::Parser.new("test[@a[a].|test]").parse
		node.parent_macro.should == nil
		(node&0).parent_macro.should == nil
		(node&0&0).parent_macro.should == node&0
		(node&0&1).parent_macro.should == node&0
		(node&0&0&0).parent_macro.should == node&0
		(node&0&1&0).parent_macro.should == node&0
	end

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

	before do
		@n = macro_node(:test)
		@p = p_node(0)
		@a = a_node(:a)
		@p << text_node("test")
		@a << text_node("test")
		@n << @p
		@n << @a
		Glyph.macro :test do
			"--#{param(0)}:#{attr(:a)}--"
		end
	end

	it "should expand the corresponding macro" do
		@n.expand({}).should == "--test:test--"
	end

	it "should resolve to an XML element" do
		reset_quiet
		@n.xml_element({})
		@n[:element].should == "test"
	end

	it "should retrieve parameter nodes easily" do
		@n.parameter(0).should == @p
		@n.parameters.should == [@p]
	end

	it "should retrieve attribute nodes easily" do
		@n.attribute(:a).should == @a
		@n.attributes.should == [@a]
	end
	
end
