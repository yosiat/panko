# frozen_string_literal: true
module Panko
  module SerializationDescriptor
    def self.build(serializer, options={})
      backend = Panko::SerializationDescriptorBackend.new

      serializer_only_filters, attributes_only_filters = resolve_filters(options, :only)
      serializer_except_filters, attributes_except_filters = resolve_filters(options, :except)

      fields, method_fields = fields_of(serializer)

      backend.type = serializer

      backend.fields = apply_filters(
        fields,
        serializer_only_filters,
        serializer_except_filters
      )

      backend.method_fields = apply_filters(
        method_fields,
        serializer_only_filters,
        serializer_except_filters
      )

      backend.has_many_associations = build_associations(
        serializer._has_many_associations,
        attributes_only_filters,
        attributes_except_filters
      )

      backend.has_one_associations = build_associations(
        serializer._has_one_associations,
        attributes_only_filters,
        attributes_except_filters
      )

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

    def self.build_associations(associations, attributes_only_filters, attributes_except_filters)
      associations.map do |association|
        options = association[:options]
        serializer_const = resolve_serializer(options[:serializer])

        options[:only] = options.fetch(:only, []) + attributes_only_filters.fetch(association[:name], [])
        options[:except] = options.fetch(:except, []) + attributes_except_filters.fetch(association[:name], [])

        [association[:name], SerializationDescriptor.build(serializer_const, options.except(:serializer))]
      end
    end

    def self.resolve_filters(options, filter)
      filters = options.fetch(filter, {})
      if filters.is_a? Array
        return filters, {}
      end

      # hash filters looks like this
      # { instance: [:a], foo: [:b] }
      # which mean, for the current instance use `[:a]` as filter
      # and for association named `foo` use `[:b]`

      serializer_filters = filters.fetch(:instance, [])
      association_filters = filters.except(:instance)

      return serializer_filters, association_filters
    end

    def self.apply_filters(fields, only, except)
      # not for now :)
      return fields if only.is_a?(Hash) || except.is_a?(Hash)

      return fields & only if only.present?
      return fields - except if except.present?

      fields
    end

    def self.resolve_serializer(serializer)
      Object.const_get(serializer.name)
    end
  end
end
