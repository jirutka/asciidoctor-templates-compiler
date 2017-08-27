# frozen_string_literal: true
require 'asciidoctor/templates_compiler/version'
require 'ruby-beautify'

module Asciidoctor::TemplatesCompiler
  module RubyBeautify
    include ::RubyBeautify
    extend self  # rubocop:disable Style/ModuleFunction

    alias pretty_string_orig pretty_string
    private :pretty_string_orig

    def pretty_string(code, indent_count: 2)
      new_lines_old = NEW_LINES
      NEW_LINES.push(:on_semicolon)  # XXX: sandbox somehow?

      s = +"module M_\n#{code}\nend\n"
      s.gsub!(/^[ \t]*;/, '')      # remove leading semicolons
      s.gsub!(/;\s*$/, '')         # remove trailing semicolons
      s.replace(pretty_string_orig(s, indent_token: "\1", indent_count: indent_count))
      s.gsub!(";\1", "\n\1")       # remove trailing semicolons after formatting
      s.gsub!(/^#{"\1" * indent_count}/, '')  # remove redundant indentation level
      s.tr!("\1", ' ')             # replace placeholder indent char with space
      s.sub!(/\Amodule M_\n/, '')  # remove wrapper module
      s.sub!(/\nend\n\z/, '')      # remove wrapper module

      NEW_LINES.replace(new_lines_old)  # XXX: not thread-safe
      s
    end

    alias call pretty_string

    # XXX: Remove after https://github.com/erniebrodeur/ruby-beautify/pull/43 is merged.
    # Overwrite this method from ::RubyBeautify with implementation that does
    # not execute ruby subprocess.
    def syntax_ok?(string)
      catch :good do
        eval "BEGIN { throw :good }; #{string}"  # rubocop:disable Security/Eval
      end
      true
    rescue SyntaxError
      false
    end
  end
end
