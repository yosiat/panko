module Panko
  class SerializationDescriptor
    def initialize(fields, method_fields)
      @fields = fields
      @method_fields = method_fields
    end

    attr_reader :fields, :method_fields

    def self.build(serializer, options)
      fields, method_fields = fields_of(serializer)

      only_filters = options.fetch(:only, [])
      except_filters = options.fetch(:except, [])

      fields = apply_filters(fields, only_filters, except_filters)
      method_fields = apply_filters(method_fields, only_filters, except_filters)

      SerializationDescriptor.new(fields, method_fields)
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

    def self.apply_filters(fields, only, except)
      # not for now :)
      return fields if only.is_a?(Hash) or except.is_a?(Hash)

      return fields & only if only.present?
      return fields - except if except.present?

      fields
    end

  end
end
