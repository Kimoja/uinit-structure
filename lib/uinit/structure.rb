# frozen_string_literal: true

require 'zeitwerk'

require 'uinit/type'
require 'uinit/memoizable'

module Uinit; end

Zeitwerk::Loader.for_gem.tap do |loader|
  loader.push_dir(__dir__, namespace: Uinit)
  loader.setup
end

module Uinit
  module Structure
    include Memoizable

    def self.included(base)
      base.extend(ClassMethods)
    end

    class Schema; end

    module ClassMethods
      include Memoizable

      memo def structure_schema
        if respond_to?(:superclass) && superclass.respond_to?(:structure_schema)
          return Class.new(superclass.structure_schema.class).new
        end

        Class.new(Schema).new
      end

      memo def structure_module
        structure_module = Module.new

        include structure_module

        structure_module
      end

      def struct(&)
        AttributeContext.scope(&).each do |attribute|
          raise NameError, 'Attribute must have a name' unless attribute.name

          structure_schema.class.define_method(attribute.name) { attribute }
          Compilers::Attribute.compile(structure_module, attribute)
        end

        Compilers::Constructor.compile(structure_module, structure_schema)
        Compilers::AsJson.compile(structure_module, structure_schema)
      end
    end

    private

    memo def _structure_schema = self.class.structure_schema
  end
end
