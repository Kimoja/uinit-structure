# frozen_string_literal: true

module Uinit
  module Structure
    class AttributeBuilder
      def initialize(defaults, attribute = nil)
        self.attribute = attribute || Attribute.new
        self.defaults = defaults

        return if attribute

        defaults.each do |(name, value)|
          self.attribute.send(:"#{name}=", value)
        end
      end

      attr_accessor :attribute, :defaults

      def attr(name, type = nil, default = Attribute::UNDEFINED, &)
        return build_mutliple(name, type, default, &) if name.is_a?(Array)

        self.name(name)

        build(type, default, &)
      end

      def abstract(type = nil, default = Attribute::UNDEFINED, &)
        build(type, default, &)
      end

      def private(*get_set)
        if get_set.empty?
          attribute.private_get = true
          attribute.private_set = true
        else
          attribute.private_get = true if get_set.include?(:get)
          attribute.private_set = true if get_set.include?(:set)
        end

        self
      end

      def name(val)
        attribute.name = val

        self
      end

      def type(val)
        attribute.type = val

        self
      end

      def struct(val = nil, &val_proc)
        attribute.struct = val.nil? ? val_proc : val

        self
      end

      def array_struct(val = nil, &val_proc)
        attribute.array_struct = val.nil? ? val_proc : val

        self
      end

      def default(val = nil, &val_proc)
        attribute.default = val.nil? ? val_proc : val

        self
      end

      def optional(val)
        attribute.optional = val

        self
      end

      def init(val)
        attribute.init = val

        self
      end

      def get(val = nil, &val_proc)
        attribute.get = val.nil? ? val_proc : val

        self
      end

      def set(val = nil, &val_proc)
        attribute.set = val.nil? ? val_proc : val

        self
      end

      def as_json(val = nil, &val_proc)
        attribute.as_json = val.nil? ? val_proc : val

        self
      end

      def alias(*aliases)
        attribute.aliases = aliases

        self
      end

      private

      def build_mutliple(name, type, default, &)
        name.map do |nm|
          builder = AttributeBuilder.new(defaults, attribute.clone)
          builder.attr(nm, type, default, &)
        end
      end

      def build(type, default, &attr_builder)
        self.type(type) unless type.nil?
        self.default(default) unless default == Attribute::UNDEFINED

        instance_eval(&attr_builder) if attr_builder

        self
      end
    end
  end
end
