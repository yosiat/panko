#include <ruby.h>

#include "attributes_iterator.h"
#include "type_cast.h"

static ID push_value_id = 0;
static ID push_array_id = 0;
static ID push_object_id = 0;
static ID pop_id = 0;

static ID each_id = 0;

static ID fields_id = 0;
static ID method_fields_id = 0;

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
                      VALUE descriptor) {
  VALUE fields = rb_funcall(descriptor, fields_id, 0);
  VALUE method_fields = rb_funcall(descriptor, method_fields_id, 0);

  panko_each_attribute(subject, fields, panko_attributes_iter, str_writer);

  long i;
  for (i = 0; i < RARRAY_LEN(method_fields); i++) {
    VALUE attribute_name = RARRAY_AREF(method_fields, i);
    // TODO: create global cache from attribute_name to rb_sym2id
    VALUE result = rb_funcall(serializer, rb_sym2id(attribute_name), 0);

    // TODO: create global cache from attribute_name to rb_sym2str
    write_value(str_writer, rb_sym2str(attribute_name), result, Qnil);
  }
}

VALUE serialize_subject(VALUE subject,
                        VALUE str_writer,
                        VALUE serializer,
                        VALUE descriptor) {
  serialize_fields(subject, str_writer, serializer, descriptor);

  return Qnil;
}

VALUE serialize_subject_api(VALUE klass,
                            VALUE subject,
                            VALUE str_writer,
                            VALUE serializer,
                            VALUE descriptor) {
  return serialize_subject(subject, str_writer, serializer, descriptor);
}

struct serialize_subjects_iter {
  VALUE str_writer;
  VALUE descriptor;
  VALUE serializer;
};

VALUE subjects_block_iter(VALUE subject, VALUE data, int argc, VALUE* argv) {
  const struct serialize_subjects_iter* iter =
      (struct serialize_subjects_iter*)data;

  VALUE str_writer = iter->str_writer;

  rb_funcall(str_writer, push_object_id, 1, Qnil);

  serialize_subject(subject, str_writer, iter->serializer, iter->descriptor);

  rb_funcall(str_writer, pop_id, 0);

  return Qundef;
}

VALUE serialize_subjects(VALUE klass,
                         VALUE subjects,
                         VALUE str_writer,
                         VALUE descriptor,
                         VALUE serializer) {
  rb_funcall(str_writer, push_array_id, 0);

  struct serialize_subjects_iter iter;
  iter.str_writer = str_writer;
  iter.descriptor = descriptor;
  iter.serializer = serializer;

  rb_block_call(subjects, each_id, 0, NULL, subjects_block_iter, (VALUE)&iter);

  rb_funcall(str_writer, pop_id, 0);

  return Qnil;
}

void Init_panko() {
  push_value_id = rb_intern("push_value");
  push_array_id = rb_intern("push_array");
  push_object_id = rb_intern("push_object");
  pop_id = rb_intern("pop");
  each_id = rb_intern("each");

  fields_id = rb_intern("fields");
  method_fields_id = rb_intern("method_fields");

  VALUE mPanko = rb_define_module("Panko");

  rb_define_singleton_method(mPanko, "serialize_subject", serialize_subject_api,
                             4);

  rb_define_singleton_method(mPanko, "serialize_subjects", serialize_subjects,
                             4);

  panko_init_attributes_iterator(mPanko);
  panko_init_type_cast(mPanko);
}
