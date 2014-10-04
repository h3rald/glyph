#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), "..", "spec_helper")

describe Node do

	def create_node
		@ht = {:a => 1, :b => 2}.to_node
	end

	it "should be a hash" do
		ht = Node.new
		expect(ht.is_a?(Hash)).to eq(true)
		expect(ht.children).to eq([])
	end

	it "should be generated from a hash" do
		create_node
		expect(@ht.respond_to?(:children)).to eq(true)
	end

	it "should support child elements" do
		create_node
		expect { @ht << "wrong" }.to raise_error
		expect { @ht << {:c => 3, :d => 4} }.not_to raise_error
		expect(@ht.children[0][:c]).to eq(3)
		expect { @ht << {:e => 5, :f => 6}.to_node }.not_to raise_error
		@ht.child(1) << {:g => 7, :h => 8}
		@ht.child(1) << {:i => 9, :j => 10}
		expect((@ht&1&1)[:j]).to eq(10)
		l = (@ht&1).length
		orphan = @ht&1&0
		expect(orphan.parent).to eq(@ht&1)
		expect((@ht&1).children.include?(orphan)).to eq(true)
		(@ht&1) >> orphan
		expect((@ht&1).children.length).to eq(l-1) 
		expect(orphan.parent).to eq(nil)
		expect((@ht&1).children.include?(orphan)).to eq(false)
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
		expect(sum).to eq(18)
		level = 0
		str = ""
		@ht.descend do |c, l|
			level = l
			c.values.sort.each { |v| str+=v.to_s}
		end
		expect(str).to eq("12347856")
		expect(level).to eq(1)
	end

	it "should store information about parent nodes" do
		create_node
		@ht << {:c => 3, :d => 4}
		@ht << {:e => 5, :f => 6}
		@ht.child(1) << {:g => 7, :h => 8}
		@ht.child(1).child(0) << {:i => 9, :j => 10}
		expect((@ht&1&0&0).parent).to eq(@ht&1&0)
		expect((@ht&1&0&0).root).to eq(@ht)
	end

	it "should find child nodes" do
		create_node
		@ht << {:c => 3, :d => 4}
		@ht << {:e => 5, :f => 6}
		result = @ht.find_child do |node|
			node[:d] == 4
		end
		expect(result.to_hash).to eq({:c => 3, :d => 4})
		result2 = @ht.find_child do |node|
			node[:q] == 7
		end
		expect(result2).to eq(nil)
	end

	it "should expose a dedicated inspect method" do
		create_node
		@ht << {:c => 3, :d => 4}
		@ht << {:e => 5, :f => 6}
		expect(@ht.inspect).to eq("#{@ht.to_hash.inspect}\n  #{(@ht&0).to_hash.inspect}\n  #{(@ht&1).to_hash.inspect}")
	end

	it "should be convertable into a hash" do
		create_node
		expect(@ht.to_hash).to eq({:a => 1, :b => 2})
		expect { @ht.to_hash.children }.to raise_error
	end

	it "should check equality of children as well" do
		create_node
		@ht << {:c => 3, :d => 4}
		@ht << {:e => 5, :f => 6}
		@ht2 = {:a => 1, :b => 2}.to_node
		@ht2 << {:c => 3, :d => 4}
		@ht2 << {:e => 5, :f => 6}
		expect(@ht==@ht2).to eq(true)
		(@ht&1)[:c] = 47
		expect(@ht==@ht2).to eq(false)
	end

end
