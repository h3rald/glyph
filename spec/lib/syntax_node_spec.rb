#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::SyntaxNode do

	it "should evaluate" do
		t = text_node("test")
		t.evaluate({})
		expect(t[:value]).to eq("test")
		e = escape_node("\\.")
		e.evaluate({})
		expect(e[:value]).to eq("\\.")
		p = p_node(0)
		a = a_node(:a)
		a << e
		p << t
		p.evaluate({}, :params => true)
		expect(p[:value]).to eq("test")
		a.evaluate({}, :attrs => true)
		expect(a[:value]).to eq("\\.")
		Glyph.macro :test do
			attribute(:a)+param(0)
		end
		m = macro_node(:test)
		m << p
		m << a
		m.evaluate({})
		expect(m[:value]).to eq("\\.test")
	end

	it "should return its parent macro" do
		node = Glyph::Parser.new("test[@a[a].|test]").parse
		expect(node.parent_macro).to eq(nil)
		expect((node&0).parent_macro).to eq(nil)
		expect((node&0&0).parent_macro).to eq(node&0)
		expect((node&0&1).parent_macro).to eq(node&0)
		expect((node&0&0&0).parent_macro).to eq(node&0)
		expect((node&0&1&0).parent_macro).to eq(node&0)
	end

	it "should convert to a string implicitly" do
		expect("#{text_node("test")}").to eq("test")
		expect("#{escape_node("\\.")}").to eq("\\.")
		expect("#{document_node}").to eq("")
		p0 = p_node(0)
		p0 << text_node("p0")
		p1 = p_node(1)
		p1 << text_node("p1")
		expect("#{p0}").to eq("p0")
		expect("#{p1}").to eq("p1")
		a = a_node(:a)
		a << text_node("a")
		b = a_node(:b)
		b << text_node("b")
		expect("#{a}").to eq("@a[a]")
		expect("#{b}").to eq("@b[b]")
		m = macro_node(:test, :escape => true)
		m << a
		m << b
		m << p0
		m << p1
		expect("#{m}").to eq("test[=@a[a]@b[b]p0|p1=]")
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
		expect(@n.expand({})).to eq("--test:test--")
	end

	it "should retrieve parameter nodes easily" do
		expect(@n.parameter(0)).to eq(@p)
		expect(@n.parameters).to eq([@p])
	end

	it "should retrieve attribute nodes easily" do
		expect(@n.attribute(:a)).to eq(@a)
		expect(@n.attributes).to eq([@a])
	end

	it "should convert escaping attributes and parameters to strings properly" do
		@a[:escape] = true
		expect(@a.to_s).to eq("@a[=test=]")
		expect(@a.contents).to eq(".[=test=]")
		@p.parent[:escape] = true
		expect(@p.to_s).to eq("test")
		expect(@p.contents).to eq(".[=test=]")
		###
		n = macro_node(:test)
		a = a_node(:a)
		a[:escape] = true
		a << text_node("alias[test\\|test1]")
		n << a
		expect(a.to_s).to eq("@a[=alias[test\\|test1]=]")
		expect(a.contents).to eq(".[=alias[test\\|test1]=]")
	end

	it "should perform macro dispatching" do
		dispatch_proc = lambda do |node|
			"dispatched: #{node[:name]}"
		end
		Glyph.macro :test_macro do
			"--test macro--"
		end
		# Parent dispatcher via parameter
		d = macro_node :dispatcher
		d[:dispatch] = dispatch_proc
		p = p_node 0
		m = macro_node :test_macro
		p << m
		d << p
		expect(m.expand({})).to eq("dispatched: test_macro")
		# Parent dispatcher via attribute
		d = macro_node :dispatcher
		d[:dispatch] = dispatch_proc
		a = a_node :attr1
		m = macro_node :test_macro
		a << m
		d << a
		expect(m.expand({})).to eq("dispatched: test_macro")
		# No dispatcher
		d = macro_node :no_dispatcher
		a = a_node :attr1
		m = macro_node :test_macro
		a << m
		d << a
		expect(m.expand({})).to eq("--test macro--")
	end
	
end
