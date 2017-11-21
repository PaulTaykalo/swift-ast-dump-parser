require 'simplecov'
SimpleCov.start

require 'codecov'
SimpleCov.formatter = SimpleCov::Formatter::Codecov

require "minitest/autorun"
require 'swift_ast_dump_parser'


