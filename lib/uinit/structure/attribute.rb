# frozen_string_literal: true

module CheerzOnRails
  module Structure
    # rubocop:disable Metrics/ClassLength
    class Attribute

      NAME_REGEX = /\A[A-Za-z]\w*\z/
      UNDEFINED = Class.new.new.freeze

      def initialize
        @private_get = false
        @private_set = false
        @name = nil
        @type = nil
        @default = UNDEFINED
        @struct = nil
        @array_struct = false
        @init = true
        @get = nil
        @set = nil
        @as_json = true
        @aliases = []
      end

      attr_accessor :default
      attr_reader :private_get,
        :private_set,
        :name,
        :type,
        :struct,
        :array_struct,
        :init,
        :get,
        :set,
        :as_json,
        :aliases

      def private_get=(val)
        raise ArgumentError, "private_get must be a boolean" unless [true, false].include?(val)

        @private_get = val
      end

      def private_set=(val)
        raise ArgumentError, "private_set must be a boolean" unless [true, false].include?(val)

        @private_set = val
      end

      def name=(val)
        optional = val.to_s.end_with?("?")

        if optional
          self.default = nil if default == UNDEFINED
          val = val.to_s.sub("?", "").to_sym
        end

        raise NameError, "Invalid attribute name '#{ val }'" unless NAME_REGEX.match?(val)

        @name = val
      end

      def type=(val)
        val = Type.from(val)
        raise ArgumentError, "type must be a Type::Base" unless val.is_a?(Type::Base)
        raise ArgumentError, "Attribute cannot have a type and a struct at the same time" if struct

        @type = val
      end

      def struct=(val)
        raise ArgumentError, "Attribute cannot have a type and a struct at the same time" if type

        if val.is_a?(Class) && val < Struct
          @struct = val
          return
        end

        raise ArgumentError, "struct must be a Struct Class or a Proc" unless val.is_a?(Proc)

        @struct =
          Class.new(Struct) do
            struct(&val)
          end
      end

      def array_struct=(val)
        self.struct = val

        @array_struct = true
      end

      def optional?
        @default != UNDEFINED
      end

      def init=(val)
        raise ArgumentError, "init must be a boolean" unless [true, false].include?(val)

        @init = val
      end

      def get=(val)
        unless val.is_a?(Proc) || val.is_a?(Symbol)
          raise ArgumentError,
            "`get` must be a Proc or a Symbol"
        end

        @get = val
      end

      def set=(val)
        unless val.is_a?(Proc) || val.is_a?(Symbol)
          raise ArgumentError,
            "`set` must be a Proc or a Symbol"
        end

        @set = val
      end

      def as_json=(val)
        unless val.is_a?(Proc) || val.is_a?(Symbol) || val == false || val == true
          raise ArgumentError,
            "`as_json` must be a Proc or a Symbol or a Boolean"
        end

        @as_json = val
      end

      def aliases=(val)
        val.each do |v|
          raise NameError, "Invalid alias name '#{ v }'" unless NAME_REGEX.match?(v)
        end

        @aliases = val
      end

      def as_json?
        @as_json != false
      end

    end
    # rubocop:enable Metrics/ClassLength
  end
end
