#include <ruby.h>
#include "serialization_descriptor_backend.h"

VALUE serialize_subject(VALUE key,
                        VALUE subject,
                        VALUE str_writer,
                        SerializationDescriptor descriptor,
                        VALUE context);

VALUE serialize_subjects(VALUE key,
                         VALUE subjects,
                         VALUE str_writer,
                         SerializationDescriptor descriptor,
                         VALUE context);
