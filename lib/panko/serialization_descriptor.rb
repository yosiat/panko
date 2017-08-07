module Panko
  class SerializationDescriptor
    def initialize(fields, method_fields, has_one_associations, has_many_associations)
      @fields = fields
      @method_fields = method_fields

      @has_one_associations = has_one_associations
      @has_many_associations = has_many_associations
    end

    attr_reader :fields, :method_fields, :has_one_associations, :has_many_associations

    def self.build(serializer, options={})
      backend = Panko::SerializationDescriptorBackend.new

      fields, method_fields = fields_of(serializer)
      backend.has_one_associations = build_associations(serializer._has_one_associations)
      backend.has_many_associations = build_associations(serializer._has_many_associations)

      only_filters = options.fetch(:only, [])
      except_filters = options.fetch(:except, [])

      backend.fields = apply_filters(fields, only_filters, except_filters)
      backend.method_fields = apply_filters(method_fields, only_filters, except_filters)


      backend
    end

    def self.fields_of(serializer)
      fields = []
      method_fields = []

      serializer._attributes.each do |attribute|
        if serializer.method_defined? attribute
          method_fields << attribute
        else
          fields << attribute
        end
      end

      return fields, method_fields
    end

    def self.build_associations(associations)
      associations.map do |association|
        options = association[:options]
        serializer_const = resolve_serializer(options[:serializer])

        [association[:name], SerializationDescriptor.build(serializer_const, options.except(:serializer))]
      end
    end

    def self.apply_filters(fields, only, except)
      # not for now :)
      return fields if only.is_a?(Hash) or except.is_a?(Hash)

      return fields & only if only.present?
      return fields - except if except.present?

      fields
    end

    def self.resolve_serializer(serializer)
      Object.const_get(serializer.name)
    end

  end
end
