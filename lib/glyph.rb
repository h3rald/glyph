#!/usr/bin/env ruby
# Glyph
#
# @website http://www.h3rald.com/glyph
# @author Fabio Cevasco (mailto:h3rald@h3rald.com)
# @copyright Copyright (c) 2009 Fabio Cevasco
# @license BSD

require 'rubygems'
require 'pathname'
require 'yaml'
require 'gli'
require 'extlib'
require 'rake'

module Glyph

	CONFIG = {}

	# Glyph's library directory
	LIB_DIR = Pathname(__FILE__).dirname.expand_path/'glyph'

	# Glyph's spec directory
	SPEC_DIR = Pathname(__FILE__).dirname.expand_path/'../spec'


	require LIB_DIR/'system_extensions'

end
