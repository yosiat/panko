#include "attributes_iterator.h"

static ID attributes_id = 0;
static ID types_id = 0;
static ID values_id = 0;

VALUE read_attributes(VALUE obj) {
  if (attributes_id == 0) {
    attributes_id = rb_intern("@attributes");
  }

  return rb_ivar_get(obj, attributes_id);
}

VALUE panko_read_lazy_attributes_hash(VALUE object) {
  VALUE attributes_set = read_attributes(object);
  if (attributes_set == Qnil) {
    return Qnil;
  }

  VALUE attributes_hash = read_attributes(attributes_set);
  if (attributes_hash == Qnil) {
    return Qnil;
  }

  return attributes_hash;
}

void panko_read_types_and_value(VALUE attributes_hash,
                                VALUE* types,
                                VALUE* values) {
  if (types_id == 0) {
    types_id = rb_intern("@types");
  }

  *types = rb_ivar_get(attributes_hash, types_id);

  if (values_id == 0) {
    values_id = rb_intern("@values");
  }

  *values = rb_ivar_get(attributes_hash, values_id);
}

VALUE panko_each_attribute(VALUE obj,
                           VALUE attributes,
                           EachAttributeFunc func,
                           VALUE context) {
  VALUE attributes_hash = panko_read_lazy_attributes_hash(obj);
  // TODO: raise error here if attributes_hash is null

  VALUE types, values;
  panko_read_types_and_value(attributes_hash, &types, &values);

  int i;
  for (i = 0; i < RARRAY_LEN(attributes); i++) {
    VALUE member = rb_sym2str(RARRAY_AREF(attributes, i));

    VALUE value = rb_hash_aref(values, member);
    VALUE type_metadata = rb_hash_aref(types, member);

    func(obj, member, value, type_metadata, context);
  }

  return Qnil;
}
