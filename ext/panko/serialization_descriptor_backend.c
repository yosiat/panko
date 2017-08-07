#include "serialization_descriptor_backend.h"

VALUE cSerializationDescriptor;

static void serialization_descriptor_free(void* ptr) {
  if (ptr == 0) {
    return;
  }

  SerializationDescriptor sd = (SerializationDescriptor)ptr;
  sd->fields = Qnil;
  sd->method_fields = Qnil;
  sd->has_one_associations = Qnil;
  sd->has_many_associations = Qnil;
}

void serialization_descriptor_mark(SerializationDescriptor data) {
  rb_gc_mark(data->fields);
  rb_gc_mark(data->method_fields);
  rb_gc_mark(data->has_one_associations);
  rb_gc_mark(data->has_many_associations);
  rb_gc_mark(data->sym2str_cache);
}

static VALUE serialization_descriptor_new(int argc, VALUE* argv, VALUE self) {
  SerializationDescriptor sd = ALLOC(struct _SerializationDescriptor);

  sd->fields = Qnil;
  sd->method_fields = Qnil;
  sd->has_one_associations = Qnil;
  sd->has_many_associations = Qnil;
  sd->sym2str_cache = rb_hash_new();

  return Data_Wrap_Struct(cSerializationDescriptor,
                          serialization_descriptor_mark,
                          serialization_descriptor_free, sd);
}

SerializationDescriptor serialization_descriptor_read(VALUE descriptor) {
  return (SerializationDescriptor)DATA_PTR(descriptor);
}

VALUE sd_sym2str(SerializationDescriptor sd, VALUE sym) {
  VALUE str = rb_hash_aref(sd->sym2str_cache, sym);
  if (str == Qnil) {
    str = rb_sym2str(sym);
    rb_hash_aset(sd->sym2str_cache, sym, str);
  }

  return str;
}

VALUE serialization_descriptor_fields_set(VALUE self, VALUE fields) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);

  sd->fields = fields;
  return Qnil;
}

VALUE serialization_descriptor_fields_ref(VALUE self) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  return sd->fields;
}

VALUE serialization_descriptor_method_fields_set(VALUE self,
                                                 VALUE method_fields) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  sd->method_fields = method_fields;
  return Qnil;
}

VALUE serialization_descriptor_method_fields_ref(VALUE self) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  return sd->method_fields;
}

VALUE serialization_descriptor_has_one_associations_set(
    VALUE self,
    VALUE has_one_associations) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  sd->has_one_associations = has_one_associations;
  return Qnil;
}

VALUE serialization_descriptor_has_one_associations_ref(VALUE self) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  return sd->has_one_associations;
}

VALUE serialization_descriptor_has_many_associations_set(
    VALUE self,
    VALUE has_many_associations) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  sd->has_many_associations = has_many_associations;
  return Qnil;
}

VALUE serialization_descriptor_has_many_associations_ref(VALUE self) {
  SerializationDescriptor sd = (SerializationDescriptor)DATA_PTR(self);
  return sd->has_many_associations;
}

void panko_init_serialization_descriptor(VALUE mPanko) {
  cSerializationDescriptor = rb_define_class_under(
      mPanko, "SerializationDescriptorBackend", rb_cObject);

  rb_define_module_function(cSerializationDescriptor, "new",
                            serialization_descriptor_new, -1);

  rb_define_method(cSerializationDescriptor,
                   "fields=", serialization_descriptor_fields_set, 1);
  rb_define_method(cSerializationDescriptor, "fields",
                   serialization_descriptor_fields_ref, 0);

  rb_define_method(cSerializationDescriptor,
                   "method_fields=", serialization_descriptor_method_fields_set,
                   1);
  rb_define_method(cSerializationDescriptor, "method_fields",
                   serialization_descriptor_method_fields_ref, 0);

  rb_define_method(cSerializationDescriptor, "has_one_associations=",
                   serialization_descriptor_has_one_associations_set, 1);
  rb_define_method(cSerializationDescriptor, "has_one_associations",
                   serialization_descriptor_has_one_associations_ref, 0);

  rb_define_method(cSerializationDescriptor, "has_many_associations=",
                   serialization_descriptor_has_many_associations_set, 1);
  rb_define_method(cSerializationDescriptor, "has_many_associations",
                   serialization_descriptor_has_many_associations_ref, 0);
}
