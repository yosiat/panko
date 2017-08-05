require_relative 'cache'
require_relative 'serialization_descriptor'
require 'oj'

module Panko
  class Serializer
    class << self
      def inherited(base)
        base._attributes = (_attributes || []).dup
        base._has_one_associations = (_has_one_associations || []).dup
        base._has_many_associations = (_has_many_associations || []).dup

        @_attributes = []
        @_has_one_associations = []
        @_has_many_associations = []
      end

      attr_accessor :_attributes, :_has_one_associations, :_has_many_associations

      def attributes(*attrs)
        @_attributes.push(*attrs).uniq!
      end

      def has_one(name, options)
        @_has_one_associations << { name: name, options: options }
      end

      def has_many(name, options)
        @_has_many_associations << { name: name, options: options }
      end
    end

    def initialize(options = {})
      @context = options.fetch(:context, nil)

      #processed_filter = process_filter options.fetch(:only, [])
      #@only = processed_filter[:serializer]
      #@only_associations = processed_filter[:associations]

      #processed_filter = process_filter options.fetch(:except, [])
      #@except = processed_filter[:serializer]
      #@except_associations = processed_filter[:associations]

      @descriptor = Panko::CACHE.fetch(self.class, options)
    end

    attr_reader :object, :context

    def serialize(object, writer = nil)
      Oj.load(serialize_to_json(object, writer))
    end

    def serialize_to_json(object, writer = nil)
      @object = object

      writer ||= Oj::StringWriter.new(mode: :rails)
      Panko::serialize_subject(object, writer, self, @descriptor)

      writer.to_s
    end


    private

    def process_filter(filter)
      return { serializer: filter, associations: {} } if filter.is_a? Array

      if filter.is_a? Hash
        # hash filters looks like this
        # { instance: [:a], foo: [:b] }
        # which mean, for the current instance use `[:a]` as filter
        # and for association named `foo` use `[:b]`

        return {
          serializer: filter.fetch(:instance, []),
          associations: filter.except(:instance)
        }
      end
    end

    def associations_code(associations)
      associations.map do |association|
        #
        # Create instance variable to store the serializer for reusing of serializer.
        #
        # Example:
        #   For `has_one :foo, serializer: FooSerializer`
        #   @foo_serializer = FooSerializer.new
        #
        options = {
          context: @context,
          only: @only_associations.fetch(association.name, []),
          except: @except_associations.fetch(association.name, [])
        }

        serializer = association.create_serializer(options)
        instance_variable_set association.serializer_name, serializer

        association.code
      end.join("\n".freeze)
    end
  end
end
