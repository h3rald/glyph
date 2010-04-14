#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Macro::Validators do

	before do
		Glyph.run 'load:macros'
		Glyph.macro :validated_test do
			validate("Invalid Macro"){	@node.parent[:macro] == :chapter }
			"Validated Test: #{@value}"
		end
	end

	it "should provide custom validation" do
		lambda { interpret("section[validated_test[invalid]]").document.output }.should raise_error
		lambda { interpret("chapter[validated_test[valid]]").document.output }.should_not raise_error
	end

	it "should validate ancestors" do
		lambda { interpret("section[eq[true]]").document.output }.should raise_error MacroError
		lambda { interpret("?[eq[true]|something]").document.output }.should_not raise_error MacroError
	end

	it "should validate parents" do
		lambda { interpret("table[td[tr[test]]]").document.output }.should raise_error MacroError
		lambda { interpret("table[tr[td[test]]]").document.output }.should_not raise_error MacroError
	end

	it "should validate the number of parameters" do
		# exact
		lambda { interpret("section[]").document.output }.should raise_error MacroError
		# none
		lambda { interpret("toc[test]").document.output }.should raise_error MacroError
		# min
		lambda { interpret("img[]").document.output }.should raise_error MacroError
		# max
		lambda { interpret("$[a|b|c]").document.output }.should raise_error MacroError
		# correct
		lambda { interpret("chapter[fmi[something|#something]]").document.output }.should_not raise_error MacroError
	end

end

