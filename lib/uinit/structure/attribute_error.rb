# frozen_string_literal: true

module CheerzOnRails
  module Structure
    class AttributeError < StandardError

      def initialize(attribute, msg)
        super(msg)

        @attribute = attribute
      end

      attr_reader :attribute

      def message
        "Error on attribute '#{ attribute.name }', detail:\n#{ super }"
      end

    end
  end
end
