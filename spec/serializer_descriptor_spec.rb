require 'spec_helper'

describe Panko::SerializationDescriptor do
  class FooSerializer < Panko::Serializer
    attributes :name, :address
  end

  context 'attributes' do
    it 'simple fields' do
      descriptor = Panko::SerializationDescriptor.build(FooSerializer)

      expect(descriptor).not_to be_nil
      expect(descriptor.fields).to eq([:name, :address])
    end

    it 'method attributes' do
      class FooWithMethodsSerializer < Panko::Serializer
        attributes :name, :address, :something

        def something
          "#{object.name} #{object.address}"
        end
      end

      descriptor = Panko::SerializationDescriptor.build(FooWithMethodsSerializer)

      expect(descriptor).not_to be_nil
      expect(descriptor.fields).to eq([:name, :address])
      expect(descriptor.method_fields).to eq([:something])
    end
  end

  context 'filter' do
    it 'only' do
      descriptor = Panko::SerializationDescriptor.build(FooSerializer, only: [:name])

      expect(descriptor).not_to be_nil
      expect(descriptor.fields).to eq([:name])
      expect(descriptor.method_fields).to be_empty
    end

    it 'except' do
      descriptor = Panko::SerializationDescriptor.build(FooSerializer, except: [:name])

      expect(descriptor).not_to be_nil
      expect(descriptor.fields).to eq([:address])
      expect(descriptor.method_fields).to be_empty
    end
  end

  context 'associations' do
    it 'has_one: build_descriptor' do
      class FooHolderHasOneSerializer < Panko::Serializer
        attributes :name

        has_one :foo, serializer: FooSerializer
      end

      descriptor = Panko::SerializationDescriptor.build(FooHolderHasOneSerializer)

      expect(descriptor).not_to be_nil
      expect(descriptor.fields).to eq([:name])
      expect(descriptor.method_fields).to be_empty

      expect(descriptor.has_one_associations.count).to eq(1)

      foo_association = descriptor.has_one_associations.first
      expect(foo_association.first).to eq(:foo)

      foo_descriptor = Panko::SerializationDescriptor.build(FooSerializer, {})
      expect(foo_association.last.fields).to eq(foo_descriptor.fields)
      expect(foo_association.last.method_fields).to eq(foo_descriptor.method_fields)
    end

    it 'has_many: builds descriptor' do
      class FoosHasManyHolderSerializer < Panko::Serializer
        attributes :name

        has_many :foos, serializer: FooSerializer
      end

      descriptor = Panko::SerializationDescriptor.build(FoosHasManyHolderSerializer)

      expect(descriptor).not_to be_nil
      expect(descriptor.fields).to eq([:name])
      expect(descriptor.method_fields).to be_empty
      expect(descriptor.has_one_associations).to be_empty

      expect(descriptor.has_many_associations.count).to eq(1)

      foo_association = descriptor.has_many_associations.first
      expect(foo_association.first).to eq(:foos)

      foo_descriptor = Panko::SerializationDescriptor.build(FooSerializer, {})
      expect(foo_association.last.fields).to eq(foo_descriptor.fields)
      expect(foo_association.last.method_fields).to eq(foo_descriptor.method_fields)
    end



    xcontext 'has_many' do

      it 'accepts only as option' do
        class FoosHolderWithOnlySerializer < Panko::Serializer
          attributes :name

          has_many :foos, serializer: FooSerializer, only: [:address]
        end

        serializer = FoosHolderWithOnlySerializer.new

        foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
        foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
        foos_holder = FoosHolder.create(name: Faker::Lorem.word, foos: [foo1, foo2]).reload

        output = serializer.serialize foos_holder

        expect(output).to eq({
          'name' => foos_holder.name,
          'foos' => [
            {
              'address' => foo1.address
            },
            {
              'address' => foo2.address
            }
          ]
        })
      end

      it 'filters associations' do
        class FoosHolderForFilterTestSerializer < Panko::Serializer
          attributes :name

          has_many :foos, serializer: FooSerializer
        end

        serializer = FoosHolderForFilterTestSerializer.new only: [:foos]

        foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
        foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
        foos_holder = FoosHolder.create(name: Faker::Lorem.word, foos: [foo1, foo2]).reload

        output = serializer.serialize foos_holder


        expect(output).to eq({
          'foos' => [
            {
              'name' => foo1.name,
              'address' => foo1.address
            },
            {
              'name' => foo2.name,
              'address' => foo2.address
            }
          ]
        })
      end
    end
  end

  xcontext 'filters' do
    it 'support nested "only" filter' do

      class FoosHolderSerializer < Panko::Serializer
        attributes :name
        has_many :foos, serializer: FooSerializer
      end

      serializer = FoosHolderSerializer.new only: { foos: [:address] }

      foo1 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foo2 = Foo.create(name: Faker::Lorem.word, address: Faker::Lorem.word).reload
      foos_holder = FoosHolder.create(name: Faker::Lorem.word, foos: [foo1, foo2]).reload

      output = serializer.serialize foos_holder

      expect(output).to eq({
        'name' => foos_holder.name,
        'foos' => [
          {
            'address' => foo1.address,
          },
          {
            'address' => foo2.address,
          }
        ]
      })
    end
  end
end
