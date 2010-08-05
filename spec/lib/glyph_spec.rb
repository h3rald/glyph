#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph do

	before do
		Glyph.enable 'project:create'
	end

	after do
		delete_project
	end

	it "should initialize a rake app and tasks" do
		Rake.application.tasks.length.should > 0
	end

	it "should run rake tasks" do
		delete_project_dir
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
		define_em_macro
		lambda { Glyph.macro_alias("->" => :ref)}.should_not raise_error
		Glyph::MACROS[:"->"].should == Glyph::MACROS[:ref]
		Glyph.macro_alias :em => :ref
		Glyph::MACROS[:em].should == Glyph::MACROS[:ref]
	end

	it "should provide a filter method to convert raw text into HTML" do
		Glyph['document.title'] = "Test"
		Glyph.filter("title[]").gsub(/\n|\t/, '').should == "<h1>Test</h1>"
	end

	it "should provide a compile method to compile files in lite mode" do
		reset_quiet
		file_copy Glyph::PROJECT/'../files/article.glyph', Glyph::PROJECT/'article.glyph'
		lambda { Glyph.compile Glyph::PROJECT/'article.glyph' }.should_not raise_error
		(Glyph::PROJECT/'article.html').exist?.should == true
	end

	it "should provide a reset method to remove config overrides, reenable tasks, clear macros and snippets." do
		Glyph['test_setting'] = true
		Glyph.reset
		Glyph::SNIPPETS.length.should == 0
		Glyph::MACROS.length.should == 0
		Glyph['test_setting'].should == nil
	end

	it "should not allow certain macros to be expanded in safe mode" do
		create_project
		Glyph.run! "load:all"
		Glyph.safe_mode = true
		lambda { output_for("include[test.glyph]")}.should raise_error Glyph::MacroError
		lambda {output_for("config:[test|true]")}.should raise_error Glyph::MacroError
		lambda { output_for("ruby[Time.now]")}.should raise_error Glyph::MacroError
		lambda { output_for("rw:[a|section[{{0}}]]")}.should raise_error Glyph::MacroError
		Glyph.safe_mode = false
	end

	it "should rewrite macros using Glyph syntax" do
		define_em_macro
		Glyph.rewrite :test_rw_macro, %{em[{{0}} -- {{a}}]}
		output_for("test_rw_macro[@a[!]?]").should == "<em>? -- !</em>"
	end

	it "should store alias information" do
		delete_project_dir
		create_project_dir
		Glyph.run! 'project:create', Glyph::PROJECT
		Glyph.run 'load:all'
		Glyph::ALIASES[:by_def][:snippet].should == [:&]
		Glyph::ALIASES[:by_alias][:"?"].should == :condition
		Glyph.macro_aliases_for(:link).should == [:"=>"]
		Glyph.macro_aliases_for(:"=>").should == nil
		Glyph.macro_definition_for(:"=>").should == :link
		Glyph.macro_definition_for(:link).should == nil
		Glyph.macro_alias?(:"#").should == true
	end

end
