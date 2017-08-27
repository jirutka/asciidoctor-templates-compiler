require 'rspec'
require 'simplecov'
require_relative 'support/matchers'

RSpec.configure do |config|
  config.color = true
end

formatters = [SimpleCov::Formatter::HTMLFormatter]
if ENV['CODACY_PROJECT_TOKEN']
  require 'codacy-coverage'
  formatters << Codacy::Formatter
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
SimpleCov.start do
  add_filter '/spec/'
end

require 'asciidoctor-templates-compiler'
