# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Layout/EmptyLinesAroundAttributeAccessor
# rubocop:disable Layout/LineLength
# rubocop:disable Lint/ConstantDefinitionInBlock
RSpec.describe Uinit::Structure do
  module SharedAttributes
    extend Uinit::Structure::AttributeContext

    def self.custo_int = int

    TypedExplicitOptional = attr(:typed_explicit_optional, custo_int, 12)
    TypedNilStr = abstract(none | str)
    TypedBoolExplicitOptional = abstract([bool], proc { [true, false] })

    ArrayStruct =
      abstract.array_struct do
        attr(%i[nested_a nested_b], any_of('a', 'b'), 'a')
      end
  end

  class BaseStruct
    include Uinit::Structure

    struct do
      private.attr(:private_get_set)
      private(:get).attr(:private_get)
      private(:set).attr(:private_set)

      attr(:untyped).required
      attr(:implicit_nil_optional?)

      attr(:typed, int).alias(:typed_str, :typed_string)

      using(SharedAttributes::TypedExplicitOptional)
      using(SharedAttributes::TypedNilStr).private.name(:typed_nil_str_implicit_optional?)
      using(SharedAttributes::TypedBoolExplicitOptional).private.name(:typed_bool_explicit_optional)

      attr(:non_initializable).init(false)
      attr(:typed_non_initializable_default, any_of('ok', 12, /why_not/), 'ok').init(false)

      attr(%i[mul_typed_a mul_typed_b], str, 'ok')

      attr(%i[mul_non_init_str_a mul_non_init_str_b], str, 'ok') do
        init(false)
      end

      attr(:custom_get_set) do
        get(:to_i)
        set(&:to_s)
      end

      attr(:as_json_false?).as_json(false)
      attr(:as_json_sym?, nil, '10').as_json(:to_i)
      attr(:as_json_proc?, nil, '10').as_json do |json, _value|
        json[:as_json_proc] = 'yeah !'
      end

      attr(:nested_struct?).struct do
        attr(%i[nested_a nested_b], any_of('a', 'b'), 'a')
      end

      using(SharedAttributes::ArrayStruct).name(:nested_array_struct?)
    end
  end

  class MyStruct < BaseStruct
    struct do
      attr(:non_inherited_attr)
    end

    def initialize(**attrs)
      initialize_structure!(attrs)
    end
  end

  subject(:initialize_structure!) do
    MyStruct.new(**base_attributes, **attributes)
  end

  let(:base_attributes) do
    {
      untyped: 'untyped',
      typed: 12,
      custom_get_set: 'custom_get_set',
      private_get_set: 'private_get_set',
      private_get: 'private_get',
      private_set: 'private_set',
      nested_struct: {
        nested_a: 'a',
        nested_b: 'b'
      },
      nested_array_struct: [
        {
          nested_a: 'a',
          nested_b: 'b'
        },
        {
          nested_a: 'b',
          nested_b: 'a'
        }
      ]
    }
  end

  let(:attributes) { { non_inherited_attr: 'non_inherited_attr' } }

  describe '.structure_schema' do
    it 'sets attributes correctly' do
      schema = MyStruct.structure_schema

      expect(schema.private_get_set.private_get).to be(true)
      expect(schema.private_get_set.private_set).to be(true)
      expect(schema.private_get.private_get).to be(true)
      expect(schema.private_get.private_set).to be(false)
      expect(schema.private_set.private_get).to be(false)
      expect(schema.private_set.private_set).to be(true)

      expect(schema.untyped.type).to be_nil
      expect(schema.implicit_nil_optional.optional?).to be(true)
      expect(schema.implicit_nil_optional.default).to be_nil

      expect(schema.typed_nil_str_implicit_optional.type).to eq(Uinit::Type::Const[nil] | Uinit::Type::Instance[String])
      expect(schema.typed_nil_str_implicit_optional.optional?).to be(true)
      expect(schema.typed_nil_str_implicit_optional.default).to be_nil

      expect(schema.typed_bool_explicit_optional.type).to eq(Uinit::Type::ArrayOf[Uinit::Type::Const[true] | Uinit::Type::Const[false]])
      expect(schema.typed_bool_explicit_optional.optional?).to be(true)
      expect(schema.typed_bool_explicit_optional.default).to be_a(Proc)

      expect(schema.typed.type).to eq(Uinit::Type::Instance[Integer])
      expect(schema.typed_explicit_optional.type).to eq(Uinit::Type::Instance[Integer])
      expect(schema.typed_explicit_optional.optional?).to be(true)
      expect(schema.typed_explicit_optional.default).to eq(12)

      expect(schema.non_initializable.init).to be(false)
      expect(schema.typed_non_initializable_default.init).to be(false)
      expect(schema.typed_non_initializable_default.type).to eq(Uinit::Type::Const['ok'] | Uinit::Type::Const[12] | Uinit::Type::Const[/why_not/])
      expect(schema.typed_non_initializable_default.default).to eq('ok')

      %i[mul_typed_a mul_typed_b].each do |mul|
        expect(schema.send(mul).type).to eq(Uinit::Type::Instance[String])
        expect(schema.send(mul).default).to eq('ok')
        expect(schema.send(mul).optional?).to be(true)
      end

      %i[mul_non_init_str_a mul_non_init_str_b].each do |mul|
        expect(schema.send(mul).type).to eq(Uinit::Type::Instance[String])
        expect(schema.send(mul).init).to be(false)
        expect(schema.send(mul).default).to eq('ok')
      end

      expect(schema.custom_get_set.get).to be_a(Symbol)
      expect(schema.custom_get_set.set).to be_a(Proc)

      expect(schema.non_inherited_attr.type).to be_nil
    end
  end

  describe '#initialize_structure!' do
    it 'works' do
      expect { initialize_structure! }.not_to raise_error
    end

    context 'when a value has the wrong type' do
      let(:attributes) do
        {
          non_inherited_attr: 'non_inherited_attr',
          typed: '12'
        }
      end

      it 'raises an AttributeTypeError' do
        expect do
          initialize_structure!
        end.to raise_error(Uinit::Structure::AttributeTypeError, /Type error on attribute 'typed'/)
      end
    end

    context 'when a value is not specified' do
      let(:attributes) { {} }

      it 'raises an AttributeTypeError' do
        expect do
          initialize_structure!
        end.to raise_error(ArgumentError, /'non_inherited_attr' must be defined/)
      end
    end
  end

  describe '#accessors' do
    it 'works' do
      struct = initialize_structure!

      expect { struct.untyped }.not_to raise_error
      expect { struct.private_get }.to raise_error(NoMethodError, /private method `private_get' called/)

      expect(struct.send(:private_get_set)).to eq('private_get_set')
      expect { struct.private_get_set }.to raise_error(NoMethodError, /private method `private_get_set' called/)
      expect do
        struct.private_get_set = 'update'
      end.to raise_error(NoMethodError, /private method `private_get_set=' called/)

      expect { struct.private_get = 'update' }.not_to raise_error
      expect(struct.send(:private_get)).to eq('update')
      expect { struct.private_get }.to raise_error(NoMethodError, /private method `private_get' called/)

      expect(struct.private_set).to eq('private_set')
      expect { struct.private_set = 'update' }.to raise_error(NoMethodError, /private method `private_set=' called/)

      expect do
        struct.typed = 'no !'
      end.to raise_error(Uinit::Structure::AttributeTypeError, /Type error on attribute 'typed'/)

      struct.custom_get_set = 12
      expect(struct.instance_variable_get(:@custom_get_set)).to eq('12')
      expect(struct.custom_get_set).to eq(12)

      expect do
        struct.send(:typed_bool_explicit_optional=, [true, 'ok'])
      end.to raise_error(Uinit::Structure::AttributeTypeError, /No type composition matches/)

      expect(struct.non_initializable).to be_nil
      expect(struct.typed_non_initializable_default).to be('ok')

      expect(struct.typed).to eq(12)
      expect(struct.typed_str).to eq(12)
      expect(struct.typed_string).to eq(12)

      struct.typed_str = 13

      expect(struct.typed).to eq(13)
      expect(struct.typed_str).to eq(13)
      expect(struct.typed_string).to eq(13)
    end
  end

  describe '#as_json' do
    let(:expected_as_json) do
      {
        mul_typed_a: 'ok',
        private_get_set: 'private_get_set',
        private_get: 'private_get',
        private_set: 'private_set',
        untyped: 'untyped',
        mul_typed_b: 'ok',
        typed: 12,
        mul_non_init_str_a: 'ok',
        typed_bool_explicit_optional: [true, false],
        non_initializable: nil,
        typed_non_initializable_default: 'ok',
        mul_non_init_str_b: 'ok',
        custom_get_set: 0,
        as_json_sym: 10,
        implicit_nil_optional: nil,
        as_json_proc: 'yeah !',
        typed_nil_str_implicit_optional: nil,
        typed_explicit_optional: 12,
        non_inherited_attr: 'non_inherited_attr',
        nested_array_struct: [{ nested_a: 'a', nested_b: 'b' }, { nested_a: 'b', nested_b: 'a' }],
        nested_struct: { nested_a: 'a', nested_b: 'b' }
      }
    end

    it 'works' do
      struct = initialize_structure!

      expect(struct.as_json).to match(expected_as_json)
    end
  end
end
# rubocop:enable Layout/EmptyLinesAroundAttributeAccessor
# rubocop:enable Layout/LineLength
# rubocop:enable Lint/ConstantDefinitionInBlock
