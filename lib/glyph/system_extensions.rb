#!/usr/bin/env ruby

class Object

	def class_instance_variable(pair)
		raise ArgumentError unless pair.pair?
		instance_variable_set "@#{pair.name.to_s}", pair.value
		self.meta_class.class_eval { attr_accessor pair.name }
	end

	unless defined? instance_exec # 1.9
    def instance_exec(*arguments, &block)
      block.bind(self)[*arguments]
    end
  end

end

class Proc #:nodoc:

  def bind(object)
    block, time = self, Time.now
    (class << object; self end).class_eval do
      method_name = "__bind_#{time.to_i}_#{time.usec}"
      define_method(method_name, &block)
      method = instance_method(method_name)
      remove_method(method_name)
      method
    end.bind(object)
  end

end

class Hash

	def pair?
		self.length == 1
	end

	def name
		return nil unless self.pair?
		keys[0]
	end

	def value
		return nil unless self.pair?
		values[0]
	end

end
