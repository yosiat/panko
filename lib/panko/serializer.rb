require_relative 'attributes/has_one'
require_relative 'attributes/has_many'
require_relative 'attributes/field'

module Panko
  class Serializer
    class << self
      def inherited(base)
        base._attributes = (_attributes || []).dup
        base._associations = (_associations || []).dup

        @_attributes = []
        @_associations = []
      end

      attr_accessor :_attributes, :_associations

      def attributes *attrs
        @_attributes.concat attrs.map { |attr| FieldAttribute.new(attr) }
      end


      def has_one name, options
        @_associations << HasOneAttribute.new(name, options)
      end

      def has_many name, options
        @_associations << HasManyAttribute.new(name, options)
      end
    end

    def initialize options={}
      @context = options.fetch(:context, nil)

      if options.has_key? :options_builder and not options[:options_builder].nil?
        options = options.merge(options[:options_builder].call(@context))
      end

      @only = options.fetch(:only, [])
      @except = options.fetch(:except, [])

      build_attributes_reader
    end

    attr_reader :object, :context

    def serialize(object)
      writer = Panko::ObjectWriter.new
      serializable_object object, writer
      writer.output
    end

    private

    RETURN_OBJECT = 'serialized_object'.freeze

    def build_attributes_reader
      attributes_reader_method_body = <<-EOMETHOD
        def serializable_object object, writer
          @object = object

          writer.push_object

          #{attributes_code}
          #{associations_code}

          writer.pop
        end
      EOMETHOD

      # TODO: don't redefine if [attributes+associations] wasn't changed
      instance_eval attributes_reader_method_body, __FILE__, __LINE__
    end

    #
    # Creates const for the given attr with it's name
    # frozen as value.
    #
    # This is for saving object allocations, so, instead of -
    # `obj["name"] = object.name`
    #
    # we do:
    # ```
    #   # once
    #   NAME = 'name'.freeze
    #
    #   # later
    #   obj[NAME] = object.name
    # ```
    def constantize_attribute attr
      unless self.class.const_defined? attr.upcase
        self.class.const_set attr.upcase, attr.to_s.freeze
      end

      attr.upcase
    end

    #
    # Generates the code for serializing attributes
    # The end result of this code for each attributes is pretty simple,
    #
    # For example:
    #   `serializable_object[NAME] = object.name`
    #
    #
    def attributes_code
      filter(self.class._attributes).map do |attr|
        const_name = constantize_attribute attr.name

        #
        # Detects what the reader should be
        #
        # for methods we it's just
        #   `attr`
        # otherwise it is:
        #   `object.attr`
        #
        reader = "object.#{attr.name}"
        if self.class.method_defined? attr.name
          reader = attr.name
        end

        "writer.push_value(#{reader}, #{const_name})"
      end.join("\n")
    end

    def associations_code
      filter(self.class._associations).map do |association|
        const_name = constantize_attribute association.name

        #
        # Create instance variable to store the serializer for reusing of serializer.
        #
        # Example:
        #   For `has_one :foo, serializer: FooSerializer`
        #   @foo_serializer = FooSerializer.new
        #
        serializer_instance_variable = "@#{association.name}_serializer"
        serializer = association.create_serializer Object.const_get(association.serializer.name), @context

        instance_variable_set serializer_instance_variable, serializer

        # TODO: has_one ? has_many ..

        output = "writer.push_key(#{const_name}) \n"
        output << "#{serializer_instance_variable}.serializable_object(object.#{association.name}, writer)"

        output
      end.join("\n")
    end

    def filter keys
      if not @only.empty?
        return keys.select { |key| @only.include? key.name }
      end

      if not @except.empty?
        return keys.reject { |key| @except.include? key.name }
      end

      keys
    end
  end
end
