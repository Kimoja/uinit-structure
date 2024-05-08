# frozen_string_literal: true

module Uinit
  module Structure
    module Compilers
      class AsJson < Base
        def initialize(mod, schema)
          super(mod)

          @schema = schema
          @attributes = schema.class.instance_methods(false).map { schema.send(_1) }
        end

        attr_reader :schema, :attributes

        def compile
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            def as_json
              #{compile_super}
              #{compile_json_attributes * "\n"}
              json
            end
          RUBY
        end

        private

        def compile_super
          unless schema.class.ancestors[1..].any? { _1 < Schema }
            return <<~RUBY
              json = {}
            RUBY
          end

          <<~RUBY
            json = super
          RUBY
        end

        def compile_json_attributes
          attributes.filter_map do |attribute|
            compile_json_attribute(attribute)
          end
        end

        def compile_json_attribute(attribute)
          return unless attribute.as_json?

          name = attribute.name

          if attribute.struct
            return compile_json_struct(name) unless attribute.array_struct

            return compile_json_array_struct(name)
          end

          return compile_json_true(name) if attribute.as_json == true

          return compile_json_sym(name, attribute.as_json) if attribute.as_json.is_a?(Symbol)

          compile_json_proc(name)
        end

        def compile_json_struct(name)
          <<~RUBY
            json[:#{name}] = self.#{name}.nil? ? nil : self.#{name}.as_json
          RUBY
        end

        def compile_json_array_struct(name)
          <<~RUBY
            json[:#{name}] = self.#{name}.nil? ? nil : self.#{name}.map(&:as_json)
          RUBY
        end

        def compile_json_true(name)
          <<~RUBY
            json[:#{name}] = self.#{name}
          RUBY
        end

        def compile_json_sym(name, sym)
          <<~RUBY
            json[:#{name}] = self.#{name}.#{sym}
          RUBY
        end

        def compile_json_proc(name)
          <<~RUBY
            _structure_schema.#{name}.as_json.call(json, self.#{name}, :#{name})
          RUBY
        end
      end
    end
  end
end
