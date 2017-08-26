require 'rspec'
require 'simplecov'
require_relative 'support/matchers'

RSpec.configure do |config|
  config.color = true
end

SimpleCov.start do
  add_filter '/spec/'
end

require 'asciidoctor-templates-compiler'
