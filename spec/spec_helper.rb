require 'rspec'
require 'simplecov'

RSpec.configure do |config|
  config.color = true
end

SimpleCov.start do
  add_filter '/spec/'
end

require 'asciidoctor-templates-compiler'
