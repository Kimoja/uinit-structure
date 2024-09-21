# frozen_string_literal: true

module Uinit
  module Structure
    module AttributeContext
      include Memoizable
      include Type::Context

      def self.scope(&)
        context = Class.new { include AttributeContext }.new
        context.instance_eval(&)

        context.attributes
      end

      memo def attributes = []

      def defaults(**defaults)
        self.attribute_defaults = defaults
      end

      def private(att_or_get_set = nil, *)
        return att_or_getset.private(:get, :set) if att_or_get_set.is_a?(AttributeBuilder)

        builder = build_attribute_builder.private(*[att_or_get_set, *].compact)
        attributes << builder.attribute

        builder
      end

      def attr(...)
        push_attribute(build_attribute_builder.attr(...))
      end

      def abstract(...)
        push_attribute(build_attribute_builder.abstract(...))
      end

      def using(attribute_builder)
        push_attribute(build_attribute_builder(attribute_builder.attribute))
      end

      private

      attr_accessor :attribute_defaults

      def build_attribute_builder(attribute = nil)
        AttributeBuilder.new(attribute_defaults || {}, attribute)
      end

      def push_attribute(builder)
        if builder.is_a?(Array)
          attributes.push(*builder.map(&:attribute))
        else
          attributes << builder.attribute
        end

        builder
      end
    end
  end
end
