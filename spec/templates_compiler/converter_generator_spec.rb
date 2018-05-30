require 'asciidoctor/templates_compiler/converter_generator'
require 'corefines'

module Asciidoctor::TemplatesCompiler
  using Corefines::String[:indent, :unindent]
  using StringExt::reindent

  describe ConverterGenerator do

    subject(:instance) do
      described_class.new(
        class_name: class_name,
        transforms_code: transforms_code,
        helpers_code: helpers_code,
        register_for: register_for,
        backend_info: backend_info,
        delegate_backend: delegate_backend,
      )
    end

    let(:class_name) { 'MyConverter' }
    let(:transforms_code) { [] }
    let(:helpers_code) { nil }
    let(:register_for) { [] }
    let(:backend_info) { {} }
    let(:delegate_backend) { nil }


    shared_examples :unknown_keyword_arg do |meth|
      it 'does not fail when given unknown keyword argument' do
        expect {
          described_class.send(meth, class_name: class_name,
                                     transforms_code: [],
                                     non_existing_arg: true)
        }.to_not raise_error
      end
    end


    describe '.generate' do
      include_examples :unknown_keyword_arg, :generate
    end


    describe '.call' do
      it 'is alias for .generate' do
        expect( described_class.method(:call) ).to eq described_class.method(:generate)
      end
    end


    describe '#initialize' do
      include_examples :unknown_keyword_arg, :new

      context 'with helpers_code w/o module Helpers' do
        let(:helpers_code) { 'def foo; end' }

        it 'raises ArgumentError' do
          expect { instance }.to raise_error ArgumentError
        end
      end
    end


    describe '#generate' do

      context 'with default out' do
        subject(:result) { instance.generate }

        it 'returns non-empty instance of StringIO' do
          is_expected.to be_a StringIO
          expect( result.string ).to_not be_empty
        end
      end

      context 'with out' do
        subject(:result) { instance.generate(out) }
        let(:out) { StringIO.new }

        it 'writes to the given out and returns it' do
          is_expected.to be_eql out
          expect( out.string ).to_not be_empty
        end
      end

      describe 'output' do
        subject(:output) { instance.generate.string }

        after(:each) do
          is_expected.to be_valid_ruby
        end

        it 'starts with comment `# This file has been generated!`' do
          is_expected.to match(/\A# This file has been generated!\n/)
        end

        it 'defines method #set_local_variables' do
          is_expected.to include <<-EOF.reindent(2)
            def set_local_variables(binding, vars)
              vars.each do |key, val|
                binding.local_variable_set(key.to_sym, val)
              end
            end
          EOF
        end

        context 'when class_name' do
          shared_examples :converter_class do
            it 'declares converter class extending ::Asciidoctor::Converter::Base' do
              is_expected.to include "class #{class_name} < ::Asciidoctor::Converter::Base"
            end
          end

          context 'is top-level class' do
            include_examples :converter_class
          end

          context 'is class inside one module' do
            let(:class_name) { 'Test::MyConverter' }

            it "declares class_name's module before the class" do
              is_expected.to match(/module Test; end.*class #{class_name}/m)
            end

            include_examples :converter_class
          end

          context 'is class inside nested module' do
            let(:class_name) { 'Mod1::Mod2::Conv' }

            it "declares all class_name's modules before the class" do
              is_expected.to match(/module Mod1; module Mod2; end end.*class #{class_name}/m)
            end

            include_examples :converter_class
          end
        end

        context 'when transforms_code is not empty' do
          let(:transforms_code) {{
            document: %(s = ""\ns << "<document>"),
            inline_image: '"<inline_image>"',
          }}

          context 'and helpers_code is not blank' do
            let(:helpers_code) { "module Helpers\nend" }

            it 'defines correct transform method for each item' do
              transforms_code.each do |name, code|
                is_expected.to include <<-EOF.unindent.%(code.indent(4)).indent(2)
                  def #{name}(node, opts = {})
                    node.extend(Helpers)
                    node.instance_eval do
                      converter.set_local_variables(binding, opts) unless opts.empty?
                  %s
                    end
                  end
                EOF
              end
            end
          end

          context 'and helpers_code is blank' do
            it 'does not extend node with Helpers in transform methods' do
              transforms_code.each do |name, _|
                is_expected.to_not match(/def #{name}\([^)]*\).*?\.extend\(Helpers\).*?\bend\b/m)
              end
            end
          end
        end

        context 'when helpers_code' do
          let(:copy_helpers_constants) do <<-EOF.reindent(2)
            # Make Helpers' constants accessible from transform methods.
            Helpers.constants.each do |const|
              const_set(const, Helpers.const_get(const))
            end
          EOF
          end

          [nil, ''].each do |value|
            context "is #{value.inspect}" do
              let(:helpers_code) { value }

              it "does not include code for copying Helper's constants into converter class" do
                is_expected.to_not include copy_helpers_constants
              end
            end
          end

          context 'is non-blank string' do
            let(:helpers_code) do <<-EOF.unindent
              module Helpers
                def help_me
                  puts 'ok'
                end
              end
            EOF
            end

            it 'includes the given helpers_code' do
              is_expected.to include helpers_code.indent(2)
            end

            it "includes code for copying Helper's constants into converter class" do
              is_expected.to include copy_helpers_constants
            end
          end
        end

        context 'when register_for' do
          context 'is empty' do
            it 'does not call register_for' do
              is_expected.to_not include 'register_for'
            end
          end

          [#|register_for       | expected           | desc              |#
            [['html5s', 'html5'], '"html5s", "html5"', 'array of strings'],
            [[:html5s, :html5]  , ':html5s, :html5'  , 'array of symbols'],
            ['html5s'           , '"html5s"'         , 'a string'],
            [:html5             , ':html5'           , 'a symbol'],
          ].each do |register_for, expected, desc|
            context "is #{desc}" do
              let(:register_for) { register_for }

              it 'calls "register_for" with given arguments' do
                is_expected.to include %(register_for #{expected}\n)
              end
            end
          end
        end

        context 'when backend_info' do
          context 'is empty' do
            it 'no backend_info parameters are set in constructor' do
              is_expected.to include <<-EOF.reindent(2)
                def initialize(backend, opts = {})
                  super
                end
              EOF
            end
          end

          context 'is not empty' do
            let(:backend_info) {{ basebackend: 'docbook', outfilesuffix: '.xml' }}

            it 'backend_info parameters are set in constructor' do
              is_expected.to include <<-EOF.reindent(2)
                def initialize(backend, opts = {})
                  super
                  basebackend "docbook"
                  outfilesuffix ".xml"
                end
              EOF
            end
          end

          context 'sets boolean parameters' do
            let(:backend_info) {{ supports_templates: true }}

            it 'backend_info parameters are set without a value' do
              is_expected.to include <<-EOF.reindent(2)
                def initialize(backend, opts = {})
                  super
                  supports_templates
                end
              EOF
            end
          end
        end

        context 'when delegate_backend' do

          let(:convert_method_code) do <<-EOF.reindent(2)
            def convert(node, transform = nil, opts = {})
              transform ||= node.node_name
              converter = %s

              if opts.empty?
                converter.send(transform, node)
              else
                converter.send(transform, node, opts)
              end
            end
          EOF
          end

          context 'is nil' do
            it 'does not declare or use @delegate_converter' do
              is_expected.to_not include '@delegate_converter'
            end

            it 'declares method #convert that does not use @delegate_converter' do
              is_expected.to include convert_method_code % 'self'
            end
          end

          context 'is not nil' do
            let(:delegate_backend) { 'html5' }

            it 'defines @delegate_converter in constructor' do
              is_expected.to include <<-EOF.reindent(2)
                def initialize(backend, opts = {})
                  super

                  delegate_backend = (opts[:delegate_backend] || "#{delegate_backend}").to_s
                  factory = ::Asciidoctor::Converter::Factory

                  converter = factory.create(delegate_backend, backend_info)
                  @delegate_converter = if converter == self
                    factory.new.create(delegate_backend, backend_info)
                  else
                    converter
                  end
                end
              EOF
            end

            it 'declares method #convert that uses @delegate_converter' do
              is_expected.to include \
                convert_method_code % 'respond_to?(transform) ? self : @delegate_converter'
            end
          end
        end
      end
    end


    describe '#call' do
      it 'is alias for #generate' do
        expect( instance.method(:call) ).to eq instance.method(:generate)
      end
    end
  end
end
