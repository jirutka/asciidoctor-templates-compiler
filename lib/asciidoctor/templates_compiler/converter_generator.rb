# frozen_string_literal: true
require 'asciidoctor/templates_compiler/version'
require 'asciidoctor/templates_compiler/string_ext'
require 'corefines'
require 'stringio'

module Asciidoctor::TemplatesCompiler
  class ConverterGenerator
    using Corefines::String[:indent, :unindent]
    using Corefines::Object::blank?
    using StringExt::reindent

    class << self
      def generate(output: StringIO.new, **opts)
        new(**opts).call(output)
      end

      alias call generate
    end

    def initialize(class_name:, transforms_code:, helpers_code: nil,
                   register_for: [], backend_info: {}, delegate_backend: nil, **)
      @class_name = class_name
      @transforms_code = transforms_code
      @helpers_code = helpers_code
      @register_for = Array(register_for)
      @backend_info = backend_info
      @delegate_backend = delegate_backend

      if !helpers_code.blank? && helpers_code !~ /\bmodule Helpers[\s#]/
        raise ArgumentError, 'The helpers_code does not contain module Helpers'
      end
    end

    def generate(out = StringIO.new)
      out << head_code << "\n"
      out << helpers_code << "\n" unless @helpers_code.blank?
      out << initialization_code << "\n"
      out << convert_method_code << "\n"
      transform_methods_code(out)
      out << support_methods_code << "\n"
      out << tail_code
      out
    end

    alias call generate

    protected

    def head_code
      init_modules = @class_name
        .split('::')[0..-2]
        .map { |name| "module #{name};" }
        .tap { |ary| ary.push('end ' * ary.size) }
        .join(' ').strip

      <<-EOF.unindent
        # This file has been generated!

        #{init_modules}
        class #{@class_name} < ::Asciidoctor::Converter::Base
      EOF
    end

    def helpers_code
      <<-EOF.unindent.%(@helpers_code).indent(2)
        #{separator 'Begin of Helpers'}
        %s

        # Make Helpers' constants accessible from transform methods.
        Helpers.constants.each do |const|
          const_set(const, Helpers.const_get(const))
        end

        #{separator 'End of Helpers'}
      EOF
    end

    def initialization_code
      setup_backend_info = if !@backend_info.empty?
        @backend_info.map { |k, v| "  #{k} #{v.inspect}" }.join("\n")
      end

      if !@register_for.empty?
        register_for = "register_for #{@register_for.map(&:inspect).join(', ')}\n"
      end

      if @delegate_backend
        delegate_converter = <<-EOF.reindent(2).rstrip

          delegate_backend = (opts[:delegate_backend] || #{@delegate_backend.inspect}).to_s
          factory = ::Asciidoctor::Converter::Factory

          converter = factory.create(delegate_backend, backend_info)
          @delegate_converter = if converter == self
            factory.new.create(delegate_backend, backend_info)
          else
            converter
          end
        EOF
      end

      [
        register_for,
        'def initialize(backend, opts = {})',
        '  super',
        setup_backend_info,
        delegate_converter,
        'end',
        '',
      ].compact.join("\n").indent(2)
    end

    def convert_method_code
      converter = if @delegate_backend
        'respond_to?(transform) ? self : @delegate_converter'
      else
        'self'
      end

      <<-EOF.reindent(2)
        def convert(node, transform = nil, opts = {})
          transform ||= node.node_name
          converter = #{converter}

          if opts.empty?
            converter.send(transform, node)
          else
            converter.send(transform, node, opts)
          end
        end
      EOF
    end

    def support_methods_code
      <<-EOF.reindent(2)
        def set_local_variables(binding, vars)
          vars.each do |key, val|
            binding.local_variable_set(key.to_sym, val)
          end
        end
      EOF
    end

    def transform_methods_code(out)
      out << "  #{separator 'Begin of generated transformation methods'}\n"

      @transforms_code.each do |name, code|
        out << "\n"
        out << "  def #{name}(node, opts = {})\n"
        out << "    node.extend(Helpers)\n" unless @helpers_code.blank?
        out << "    node.instance_eval do\n"
        out << "      converter.set_local_variables(binding, opts) unless opts.empty?\n"
        out << code.indent(6, ' ') << "\n"
        out << "    end\n"
        out << "  end\n"
      end

      out << "  #{separator 'End of generated transformation methods'}\n"
    end

    def tail_code
      "end\n"
    end

    private

    def separator(title)
      dashes = '-' * ((76 - title.length) / 2)
      "##{dashes} #{title} #{dashes}#\n"
    end
  end
end
