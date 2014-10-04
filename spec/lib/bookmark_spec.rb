# encoding: utf-8

#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Bookmark do

	before do
		@b = Glyph::Bookmark.new :id => :test, :file => "test.glyph"
	end

	it "should be initialized with at least an id" do
		expect { Glyph::Bookmark.new }.to raise_error
		expect { Glyph::Bookmark.new({:id => :test}) }.not_to raise_error
		expect { Glyph::Bookmark.new({:file => "test"}) }.to raise_error
		expect { Glyph::Bookmark.new({:id => "test", :file => "test.glyph"}) }.not_to raise_error
	end

	it "shiuld expose title, code and file" do
		expect(@b.file).to eq("test.glyph")
		expect(@b.code).to eq(:test)
		expect(@b.title).to eq(nil)
		expect(Glyph::Bookmark.new(:id => :test2, :title => "Test 2").title).to eq("Test 2")
	end

	it "should convert to a string" do
		@b.code.to_s == @b.to_s
		expect("#{@b}").to eq(@b.to_s)
	end

	it "should format the link for a single output file" do
		# Link within the same file
		expect(@b.link).to eq("#test")
		# Link to a different file file
		expect(@b.link('intro.glyph')).to eq("#test")
	end

	it "should format the link for multiple output files" do
		out = Glyph['document.output']
		Glyph['document.output'] = 'web'
		# Link within the same file
		expect(@b.link("test.glyph")).to eq("#test")
		# Link to a different file file
		expect(@b.link("intro.glyph")).to eq("/test.html#test")
		# Test that base directory is added correctly
		Glyph["output.#{Glyph['document.output']}.base"] = ""
		expect(@b.link("intro.glyph")).to eq("test.html#test")
		expect(@b.link("test.glyph")).to eq("#test")
		Glyph['document.output'] = out
	end

	it "should check ID validity" do
		expect { Glyph::Bookmark.new :id => "#test$", :file => "test.glyph"}.to raise_error(RuntimeError, "Invalid bookmark ID: #test$")		
	end

	it "should check bookmark equality" do
		expect(@b).to eq(Glyph::Bookmark.new(:id => :test, :file => 'test.glyph'))
		expect(@b).to eq(Glyph::Bookmark.new(:id => :test, :file => "test.glyph"))
		expect(@b).to eq(Glyph::Bookmark.new(:id => :test, :file => 'test.glyph', :level => 2))
		expect(@b).not_to eq(Glyph::Bookmark.new(:id => :test1, :file => 'test.glyph'))
		expect(@b).not_to eq(Glyph::Bookmark.new(:id => :test, :file => 'test1.glyph'))
	end

end
