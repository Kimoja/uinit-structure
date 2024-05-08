# frozen_string_literal: true

module Uinit
  module Structure
    module Compilers
      class Base
        def self.compile(...)
          new(...).compile
        end

        def initialize(mod)
          @mod = mod
        end

        attr_reader :mod

        def compile_method(str, file, line)
          mod.class_eval(str.gsub(/^$\s*\n/, '').gsub(/\s+$/, ''), file, line)
        end
      end
    end
  end
end
