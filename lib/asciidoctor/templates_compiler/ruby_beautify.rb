require 'asciidoctor/templates_compiler/version'
require 'ruby-beautify'

module Asciidoctor::TemplatesCompiler
  module RubyBeautify
    extend self

    def pretty_string(code, indent_count: 2)
      new_lines_old = ::RubyBeautify::NEW_LINES
      ::RubyBeautify::NEW_LINES.push(:on_semicolon)  # XXX: sandbox somehow?

      s = "def __\n#{code}\nend\n"
      s.gsub! /^;/, ''         # remove leading semicolons
      s.gsub! /;\s*$/, ''      # remove trailing semicolons
      s.replace ::RubyBeautify.pretty_string(s, indent_token: "\1", indent_count: indent_count)
      s.gsub! ";\1", "\n\1"    # remove trailing semicolons after formatting
      s.gsub! "\1", ' '        # replace placeholder indent char with space
      s.sub! /\Adef __\n/, ''  # remove wrapper method
      s.sub! /\nend\n\z/, ''   # remove wrapper method

      ::RubyBeautify::NEW_LINES.replace(new_lines_old)  # XXX: not thread-safe
      s
    end

    alias :call :pretty_string
  end
end
