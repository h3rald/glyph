#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Glyph::Node do

	def create_node
		@ht = {:a => 1, :b => 2}.to_node
	end

	it "should be a hash" do
		ht = Glyph::Node.new
		ht.is_a?(Hash).should == true
		ht.children.should == []
	end

	it "should be generated from a hash" do
		create_node
		@ht.respond_to?(:children).should == true
	end

	it "should support child elements" do
		create_node
		lambda { @ht << "wrong" }.should raise_error
		lambda { @ht << {:c => 3, :d => 4} }.should_not raise_error
		@ht.children[0][:c].should == 3
		lambda { @ht << {:e => 5, :f => 6}.to_node }.should_not raise_error
		@ht.child(1) << {:g => 7, :h => 8}
		@ht.child(1) << {:i => 9, :j => 10}
		((@ht>>1>>1)[:j]).should == 10
	end
	
	it "should support iteration" do
		create_node
		@ht << {:c => 3, :d => 4}
		@ht << {:e => 5, :f => 6}
		@ht.child(0) << {:g => 7, :h => 8}
		sum = 0
		@ht.each_child do |c|
			c.values.each { |v| sum+=v}
		end
		sum.should == 18
		level = 0
		str = ""
		@ht.descend do |c, l|
			level = l
			c.values.sort.each { |v| str+=v.to_s}
		end
		str.should == "12347856"
		level.should == 1
	end

	it "should store information about parent nodes" do
		create_node
		@ht << {:c => 3, :d => 4}
		@ht << {:e => 5, :f => 6}
		@ht.child(1) << {:g => 7, :h => 8}
		@ht.child(1).child(0) << {:i => 9, :j => 10}
		(@ht>>1>>0>>0).parent.should == @ht>>1>>(0)
		(@ht>>1>>0>>0).root.should == @ht
	end


end
