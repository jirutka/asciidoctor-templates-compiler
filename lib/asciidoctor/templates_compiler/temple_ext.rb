# frozen_string_literal: true
require 'temple'

module Temple
  # Monkey-patch Temple::Generator to fix bugs/inconviences waiting to be
  # merged into upstream.
  class Generator

    # XXX: Remove after https://github.com/judofyr/temple/pull/113 is merged.
    def initialize(opts = {})
      self.class.options[:capture_generator] = self.class
      super
    end

    # XXX: Remove after https://github.com/judofyr/temple/pull/112 is merged.
    def on_capture(name, exp)
      capture_generator.new(**options, buffer: name).call(exp)
    end
  end
end
