# frozen_string_literal: true

module Uinit
  module Structure
    module Compilers
      # rubocop:disable Metrics/ClassLength
      class Attribute < Base
        def initialize(mod, attribute)
          super(mod)

          @attribute = attribute
        end

        attr_reader :attribute

        def compile
          compile_getter
          compile_predicate
          compile_setter
          compile_aliases
        end

        private

        def compile_getter
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            #{vis(:get)}def #{attribute.name}
              return #{compile_get}
            end
          RUBY
        end

        def compile_get
          case attribute.get
          when Symbol
            <<~RUBY.strip
              @#{attribute.name}.#{attribute.get}
            RUBY
          when Proc
            <<~RUBY.strip
              #{lookup(:get)}.call(@#{attribute.name})
            RUBY
          else
            <<~RUBY.strip
              @#{attribute.name}
            RUBY
          end
        end

        def compile_predicate
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            #{vis(:get)}def #{attribute.name}?; @#{attribute.name}.present? end
          RUBY
        end

        def compile_setter
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            #{vis(:set)}def #{attribute.name}=(value)
              #{compile_set}
              #{compile_struct}
              #{compile_array_struct}
              #{compile_type}
              @#{attribute.name} = value
            end
          RUBY
        end

        def compile_set
          case attribute.set
          when Symbol
            <<~RUBY.strip
              value = value.#{lookup(:set)}
            RUBY
          when Proc
            <<~RUBY.strip
              value = #{lookup(:set)}.call(value)
            RUBY
          else
            ''
          end
        end

        def compile_struct
          return unless attribute.struct && !attribute.array_struct

          compile_optional_check(<<~RUBY)
            unless value.is_a?(#{lookup(:struct)})
              unless value.is_a?(Hash)
                raise AttributeError.new(#{lookup}, "no implicit conversion of \#{ value.class } into Hash")
              end

              value = #{lookup(:struct)}.new(**value)
            end
          RUBY
        end

        def compile_array_struct
          return unless attribute.struct && attribute.array_struct

          compile_optional_check(<<~RUBY)
            unless value.is_a?(Array)
              raise AttributeError.new(#{lookup}, "no implicit conversion of \#{ value.class } into Array")
            end

            struct = #{lookup(:struct)}

            value = value.map do |val|
              next val if val.is_a?(struct)

              unless val.is_a?(Hash)
                raise AttributeError.new(#{lookup}, "no implicit conversion of \#{ val.class } into Hash")
              end

              struct.new(**val)
            end
          RUBY
        end

        def compile_optional_check(code)
          return code unless attribute.optional? && attribute.default.nil?

          <<~RUBY
            unless value.nil?
              #{code}
            end
          RUBY
        end

        def compile_type
          return unless attribute.type

          <<~RUBY
            begin
              #{lookup(:type)}.is!(value)
            rescue Type::Error => error
              raise AttributeTypeError.new(#{lookup}, error)
            end
          RUBY
        end

        def compile_aliases
          attribute.aliases.each do |alia|
            compile_alias_get(alia)
            compile_alias_predicate(alia)
            compile_alias_set(alia)
          end
        end

        def compile_alias_get(alia)
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            #{vis(:get)}def #{alia}
              self.#{attribute.name}
            end
          RUBY
        end

        def compile_alias_predicate(alia)
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            #{vis(:get)}def #{alia}?
              self.#{attribute.name}?
            end
          RUBY
        end

        def compile_alias_set(alia)
          compile_method(<<~RUBY, __FILE__, __LINE__ + 1)
            #{vis(:get)}def #{alia}=(value)
              self.#{attribute.name} = value
            end
          RUBY
        end

        def vis(met)
          if (met == :get && attribute.private_get) ||
             (met == :set && attribute.private_set)
            'private '
          else
            ''
          end
        end

        def lookup(att = nil)
          "__structure_schema.#{attribute.name}#{att ? ".#{att}" : ''}"
        end
      end
      # rubocop:enable Metrics/ClassLength
    end
  end
end
