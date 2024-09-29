# frozen_string_literal: true

require 'zeitwerk'

require 'active_support'

require 'uinit/type'
require 'uinit/memoizable'

module Uinit; end

Zeitwerk::Loader.for_gem.tap do |loader|
  loader.push_dir(__dir__, namespace: Uinit)
  loader.setup
end

module Uinit
  module Structure
    extend ActiveSupport::Concern
    include Memoizable

    class Schema; end

    class_methods do
      include Memoizable

      attr_reader :attributes, :attributes_scope

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
        self.attributes_scope = AttributeScope.new(self)
        attributes = attributes_scope.scope(&).attributes

        attributes.each do |attribute|
          raise NameError, 'Attribute must have a name' unless attribute.name

          structure_schema.class.define_method(attribute.name) { attribute }
          Compilers::Attribute.compile(structure_module, attribute)
        end

        Compilers::Constructor.compile(structure_module, structure_schema)
        Compilers::AsJson.compile(structure_module, structure_schema)

        sup_attributes = superclass < Structure ? superclass.attributes.dup : {}

        self.attributes = attributes.each_with_object(sup_attributes) do |attribute, hsh|
          hsh[attribute.name] = attribute
        end

        self.attributes_scope = nil
      end

      private

      attr_writer :attributes, :attributes_scope
    end

    memo def get_structure_schema = self.class.structure_schema
    memo def get_attributes = self.class.attributes
  end
end
