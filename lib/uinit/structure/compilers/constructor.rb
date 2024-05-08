# frozen_string_literal: true

module CheerzOnRails
  module Structure
    module Compilers
      class Constructor < Base

        def initialize(mod, schema)
          super(mod)

          @schema = schema
          @attributes = schema.class.instance_methods(false).map { schema.send(_1) }
        end

        attr_reader :schema, :attributes

        def compile
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            def initialize_structure!(hsh)
              #{ compile_super }
              #{ compile_attribute_initializers * "\n" }
            end
          RUBY
        end

        private

        def compile_super
          return unless schema.class.ancestors[1..].any? do |ancestor|
            ancestor < Schema
          end

          <<~RUBY
            begin
              super(hsh)
            end
          RUBY
        end

        def compile_attribute_initializers
          attributes.filter_map do |attribute|
            compile_attribute_initializer(attribute)
          end
        end

        def compile_attribute_initializer(attribute)
          name = attribute.name

          unless attribute.init
            return unless attribute.optional?

            return compile_default_attribute(name, attribute)
          end

          return compile_non_optional_attribute(name) unless attribute.optional?

          compile_optional_attribute(name, attribute)
        end

        def compile_non_optional_attribute(name)
          <<~RUBY
            raise ArgumentError, "'#{ name }' must be defined" unless hsh.key?(:#{ name })
            self.#{ name } = hsh[:#{ name }]
          RUBY
        end

        def compile_optional_attribute(name, attribute)
          <<~RUBY
            if hsh.key?(:#{ name })
              self.#{ name } = hsh[:#{ name }]
            else
              #{ compile_default_attribute(name, attribute) }
            end
          RUBY
        end

        def compile_default_attribute(name, attribute)
          <<~RUBY
            self.#{ name } = _structure_schema.#{ name }.default#{ attribute.default.is_a?(Proc) ? ".call" : "" }
          RUBY
        end

      end
    end
  end
end
