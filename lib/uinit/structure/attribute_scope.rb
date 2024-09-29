# frozen_string_literal: true

module Uinit
  module Structure
    class AttributeScope
      include AttributeContext

      def initialize(context)
        self.context = context
      end

      def scope(&scope)
        instance_eval(&scope) if scope

        self
      end

      def method_missing(name, ...)
        context.send(name, ...)
      end

      private

      attr_accessor :context
    end
  end
end
