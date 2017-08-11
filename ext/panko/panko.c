#include <ruby.h>

#include "attributes_iterator.h"
#include "panko.h"
#include "type_cast.h"

static ID push_value_id = 0;
static ID push_array_id = 0;
static ID push_object_id = 0;
static ID pop_id = 0;

static ID to_a_id = 0;

void write_value(VALUE str_writer,
                 VALUE key,
                 VALUE value,
                 VALUE type_metadata) {
  if (type_metadata != Qnil) {
    value = type_cast(type_metadata, value);
  }

  rb_funcall(str_writer, push_value_id, 2, value, key);
}

void panko_attributes_iter(VALUE object,
                           VALUE name,
                           VALUE value,
                           VALUE type_metadata,
                           VALUE context) {
  write_value(context, name, value, type_metadata);
}

void serialize_fields(VALUE subject,
                      VALUE str_writer,
                      VALUE serializer,
                      SerializationDescriptor descriptor) {
  panko_each_attribute(subject, descriptor, descriptor->fields,
                       panko_attributes_iter, str_writer);

  VALUE method_fields = descriptor->method_fields;
  long i;
  for (i = 0; i < RARRAY_LEN(method_fields); i++) {
    VALUE attribute_name = RARRAY_AREF(method_fields, i);
    // TODO: create global cache from attribute_nabe to rb_sym2id
    VALUE result = rb_funcall(serializer, rb_sym2id(attribute_name), 0);

    write_value(str_writer, rb_sym2str(attribute_name), result, Qnil);
  }
}

void serialize_has_one_associatoins(VALUE subject,
                                    VALUE str_writer,
                                    SerializationDescriptor descriptor,
                                    VALUE associations) {
  long i;
  for (i = 0; i < RARRAY_LEN(associations); i++) {
    VALUE association = RARRAY_AREF(associations, i);

    VALUE name = RARRAY_AREF(association, 0);
    VALUE association_descriptor = RARRAY_AREF(association, 1);
    VALUE value = rb_funcall(subject, rb_sym2id(name), 0);

    serialize_subject(rb_sym2str(name), value, str_writer, Qnil,
                      serialization_descriptor_read(association_descriptor));
  }
}

void serialize_has_many_associatoins(VALUE subject,
                                     VALUE str_writer,
                                     SerializationDescriptor descriptor,
                                     VALUE associations) {
  long i;
  for (i = 0; i < RARRAY_LEN(associations); i++) {
    VALUE association = RARRAY_AREF(associations, i);

    VALUE name = RARRAY_AREF(association, 0);
    VALUE association_descriptor = RARRAY_AREF(association, 1);
    VALUE value = rb_funcall(subject, rb_sym2id(name), 0);

    serialize_subjects(rb_sym2str(name), value, str_writer,
                       serialization_descriptor_read(association_descriptor),
                       Qnil);
  }
}

VALUE serialize_subject(VALUE key,
                        VALUE subject,
                        VALUE str_writer,
                        VALUE serializer,
                        SerializationDescriptor descriptor) {
  rb_funcall(str_writer, push_object_id, 1, key);

  serialize_fields(subject, str_writer, serializer, descriptor);

  if (RARRAY_LEN(descriptor->has_one_associations) >= 0) {
    serialize_has_one_associatoins(subject, str_writer, descriptor,
                                   descriptor->has_one_associations);
  }

  if (RARRAY_LEN(descriptor->has_many_associations) >= 0) {
    serialize_has_many_associatoins(subject, str_writer, descriptor,
                                    descriptor->has_many_associations);
  }

  rb_funcall(str_writer, pop_id, 0);

  return Qnil;
}

VALUE serialize_subject_api(VALUE klass,
                            VALUE subject,
                            VALUE str_writer,
                            VALUE serializer,
                            VALUE descriptor) {
  return serialize_subject(Qnil, subject, str_writer, serializer,
                           serialization_descriptor_read(descriptor));
}

VALUE serialize_subjects(VALUE key,
                         VALUE subjects,
                         VALUE str_writer,
                         SerializationDescriptor descriptor,
                         VALUE serializer) {
  rb_funcall(str_writer, push_array_id, 1, key);

  if (!RB_TYPE_P(subjects, T_ARRAY)) {
    subjects = rb_funcall(subjects, to_a_id, 0);
  }

  long i;
  for (i = 0; i < RARRAY_LEN(subjects); i++) {
    VALUE subject = RARRAY_AREF(subjects, i);

    serialize_subject(Qnil, subject, str_writer, serializer, descriptor);
  }

  rb_funcall(str_writer, pop_id, 0);

  return Qnil;
}

VALUE serialize_subjects_api(VALUE klass,
                             VALUE subjects,
                             VALUE str_writer,
                             VALUE descriptor,
                             VALUE serializer) {
  serialize_subjects(Qnil, subjects, str_writer,
                     serialization_descriptor_read(descriptor), serializer);

  return Qnil;
}

void Init_panko() {
  CONST_ID(push_value_id, "push_value");
  CONST_ID(push_array_id, "push_array");
  CONST_ID(push_object_id, "push_object");
  CONST_ID(pop_id, "pop");
  CONST_ID(to_a_id, "to_a");

  VALUE mPanko = rb_define_module("Panko");

  rb_define_singleton_method(mPanko, "serialize_subject", serialize_subject_api,
                             4);

  rb_define_singleton_method(mPanko, "serialize_subjects",
                             serialize_subjects_api, 4);

  panko_init_serialization_descriptor(mPanko);
  panko_init_attributes_iterator(mPanko);
  panko_init_type_cast(mPanko);
}
