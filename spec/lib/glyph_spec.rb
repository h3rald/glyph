#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph do

	before do
		Glyph.enable 'project:create'
	end

	it "should initialize a rake app and tasks" do
		Glyph::APP.tasks.length.should > 0
	end

	it "should run rake tasks" do
		create_project_dir
		Glyph.run 'project:create', Glyph::PROJECT
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should raise_error
		delete_project_dir
		create_project_dir
		lambda { Glyph.run! 'project:create', Glyph::PROJECT }.should_not raise_error
		delete_project_dir
	end

	it "should define macros" do
		lambda { define_em_macro }.should_not raise_error
		lambda { define_ref_macro }.should_not raise_error
		Glyph::MACROS.include?(:em).should == true
		Glyph::MACROS.include?(:ref).should == true
	end

	it "should support macro aliases" do
		define_ref_macro
		lambda { Glyph.macro_alias("->" => :ref)}.should_not raise_error
		Glyph::MACROS[:"->"].should == Glyph::MACROS[:ref]
	end



end
