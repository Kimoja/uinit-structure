# frozen_string_literal: true

module Uinit
  module Structure
    class AttributeTypeError < StandardError
      def initialize(attribute, type_error)
        super()

        @attribute = attribute
        @type_error = type_error

        set_backtrace(type_error.backtrace)
      end

      attr_reader :attribute, :type_error

      def message
        "Type error on attribute '#{attribute.name}', detail:\n#{type_error.message}"
      end
    end
  end
end
