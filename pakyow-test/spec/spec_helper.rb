require_relative '../lib/pakyow-test'

if ENV['COVERAGE']
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start
end
