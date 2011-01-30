#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Macro::Validators do

	before do
		create_project
		Glyph.run! 'load:all'
		Glyph.macro :validated_test do
			validate("Invalid Macro"){	value == "valid" }
			"Validated Test: #{value}"
		end
	end

	after do
		reset_quiet
		delete_project
	end

	it "should provide custom validation" do
		lambda { interpret("section[validated_test[invalid]]").document.output }.should raise_error Glyph::MacroError
		lambda { interpret("chapter[validated_test[valid]]").document.output }.should_not raise_error
	end

	it "should validate the number of parameters" do
		# exact
		lambda { interpret("section[sfsdg|saf]").document.output }.should raise_error Glyph::MacroError
		# none
		lambda { interpret("title[test]").document.output }.should raise_error Glyph::MacroError
		# min
		lambda { interpret("?[]").document.output }.should raise_error Glyph::MacroError
		# max
		lambda { interpret("not[a|b|c]").document.output }.should raise_error Glyph::MacroError
		# correct
		lambda { interpret("chapter[fmi[something|#something]]").document.output }.should_not raise_error Glyph::MacroError
	end

	it "should check for mutual inclusion" do
		Glyph::SNIPPETS[:inc] = "Test &[inc]"
		lambda {interpret("&[inc] test").document}.should raise_error(Glyph::MutualInclusionError)
	end

	it "should validate XML elements" do
		language 'xml'
		lambda { interpret("<test[test]").document}.should raise_error
		lambda { interpret("_test[test]").document}.should_not raise_error
	end

	it "should validate XML attributes" do
		language 'xml'
		output_for("test[test @.test[test]]").should == "<test>test </test>"
	end

	it "should validate required attributes" do
		Glyph['document.output'] = 'web'
		Glyph.run! 'load:macros'
		lambda { output_for("section[section[@src[test]]]") }.should raise_error(Glyph::MacroError, "Macro 'section' requires a 'title' attribute")
	end

	it "should validate if a macro is within another one" do
		define_em_macro
		Glyph.macro :within_m do
			within :em
			"---"
		end
		lambda { output_for("within_m[test]") }.should raise_error(Glyph::MacroError, "Macro 'within_m' must be within a 'em' macro")
	end	

	it "should validate if a macro is not within another one" do
		define_em_macro
		Glyph.macro :within_m do
			not_within :em
			"---"
		end
		lambda { output_for("em[within_m[test]]") }.should raise_error(Glyph::MacroError, "Macro 'within_m' must not be within a 'em' macro")
	end	

	it "should validate if macro contains quoted parameters" do
		Glyph.run! 'load:macros'
		Glyph.macro :q_par_0 do
			quoted_parameter 0
			"---"
		end
		Glyph.macro :q_par_1 do
			quoted_parameter 1
			"---"
		end
		lambda { puts output_for("q_par_0[.|'[test]]") }.should raise_error(Glyph::MacroError, "Macro 'q_par_0' requires a quoted macro at position 0")
		output_for("q_par_1[.|'[test]]").should == "---"
	end

end

