require "concurrent"


module Panko
  # Serialers Cache
  #
  # the whole point of this cache, that instead of creating serializers
  # manually (via Object#new) we will use this class therefore we will use
  # utilize Panko's magic point - reusing serializers.
  #
  # This cache may contain the multiple instance of the same serializer type,
  # because the serializer can generate different code with only and except.
  #
  # Important: we don't store ArraySerializer, since re-using them don't give a lot,
  # only reusing their `each_serializer` can help.
  class Cache
    def initialize
      @_cache = Concurrent::Map.new
    end

    def fetch(serializer_const, options)
      serializer_key = build_key(serializer_const, options[:only], options[:except])
      serializer = @_cache.compute_if_absent(serializer_key) {
        SerializationDescriptor.build(serializer_const, only: options.fetch(:only, []), except: options.fetch(:except, []))
      }

      serializer
    end

    private

    #
    # Create key based on what we define unique serializer
    #
    def build_key(serializer_const, only, except)
      [serializer_const, only, except].hash
    end
  end

  CACHE = Panko::Cache.new
end

