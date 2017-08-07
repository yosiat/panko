#include <ruby.h>

#ifndef __SD_H__
#define __SD_H__

typedef struct _SerializationDescriptor {
  VALUE fields;
  VALUE method_fields;
  VALUE has_one_associations;
  VALUE has_many_associations;

  VALUE sym2str_cache;
} * SerializationDescriptor;

VALUE serialization_descriptor_fields_ref(VALUE descriptor);
VALUE serialization_descriptor_method_fields_ref(VALUE descriptor);
VALUE serialization_descriptor_has_one_associations_ref(VALUE descriptor);
VALUE serialization_descriptor_has_many_associations_ref(VALUE descriptor);

SerializationDescriptor serialization_descriptor_read(VALUE descriptor);
VALUE sd_sym2str(SerializationDescriptor sd, VALUE sym);

void panko_init_serialization_descriptor(VALUE mPanko);

#endif
