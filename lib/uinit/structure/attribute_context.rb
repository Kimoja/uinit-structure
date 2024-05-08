# frozen_string_literal: true

module CheerzOnRails
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

      def private(att_or_get_set = nil, *)
        return att_or_getset.private(:get, :set) if att_or_get_set.is_a?(AttributeBuilder)

        builder = AttributeBuilder.new.private(*[att_or_get_set, *].compact)
        attributes << builder.attribute

        builder
      end

      def attr(...)
        push_attribute(AttributeBuilder.new.attr(...))
      end

      def abstract(...)
        push_attribute(AttributeBuilder.new.abstract(...))
      end

      def using(attribute_builder)
        push_attribute(AttributeBuilder.new(attribute_builder.attribute))
      end

      private

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
