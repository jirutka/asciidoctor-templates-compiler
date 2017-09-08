# frozen_string_literal: true
require 'corefines'

module Asciidoctor::TemplatesCompiler
  # @private
  module StringExt
    module Reindent
      refine ::String do
        using ::Corefines::String[:indent, :unindent]

        def reindent(level, indent_str = ' ')
          unindent.indent!(level, indent_str)
        end
      end
    end

    include ::Corefines::Support::AliasSubmodules
  end
end
