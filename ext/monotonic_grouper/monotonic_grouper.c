#include <ruby.h>
#include <ruby/encoding.h>

#ifndef RB_BIGNUM_TYPE_P
#define RB_BIGNUM_TYPE_P(obj) (RB_TYPE_P((obj), T_BIGNUM))
#endif

static inline void seal_array_len(VALUE ary, VALUE *buf, long pos) {
    if (pos == 0)
        return;
    rb_ary_store(ary, pos - 1, buf[pos - 1]);
}

static VALUE rb_mMonotonicGrouper;
static VALUE rb_cDate;
static ID id_succ;
static ID id_jd;

#define CHECK_ARRAY_MUTATION(ary, expected_len)                                \
    do {                                                                       \
        if (RARRAY_LEN(ary) != (expected_len)) {                               \
            rb_raise(rb_eRuntimeError, "array was modified during iteration"); \
        }                                                                      \
    } while (0)

static VALUE process_fixnum_array(VALUE self, long len, long min_range_size) {
    const VALUE *ptr = RARRAY_CONST_PTR(self);
    const VALUE *end_ptr = ptr + len;

    VALUE result = rb_ary_new_capa(len);
    VALUE *out = RARRAY_PTR(result);
    long pos = 0;

    long group_start = FIX2LONG(*ptr);
    long prev = group_start;
    const VALUE *p;

    for (p = ptr + 1; p < end_ptr; p++) {
        VALUE raw = *p;

        if (!FIXNUM_P(raw)) {
            rb_raise(rb_eTypeError, "All elements must be of the same type");
        }

        long curr = FIX2LONG(raw);

        if (curr == prev + 1) {
            prev = curr;
        } else {
            long size = prev - group_start + 1;
            if (size >= min_range_size) {
                out[pos++] = rb_range_new(LONG2FIX(group_start), LONG2FIX(prev), 0);
            } else {
                long v;
                for (v = group_start; v <= prev; v++) {
                    out[pos++] = LONG2FIX(v);
                }
            }
            group_start = curr;
            prev = curr;
        }
    }

    {
        long size = prev - group_start + 1;
        if (size >= min_range_size) {
            out[pos++] = rb_range_new(LONG2FIX(group_start), LONG2FIX(prev), 0);
        } else {
            long v;
            for (v = group_start; v <= prev; v++) {
                out[pos++] = LONG2FIX(v);
            }
        }
    }

    seal_array_len(result, out, pos);
    return result;
}

static VALUE process_date_array(VALUE self, long len, long min_range_size, VALUE first_elem) {
    VALUE result = rb_ary_new_capa(len);
    VALUE *out = RARRAY_PTR(result);
    long pos = 0;

    VALUE group_start = first_elem;
    VALUE prev_value = first_elem;
    VALUE first_class = CLASS_OF(first_elem);
    long prev_jd = NUM2LONG(rb_funcall(first_elem, id_jd, 0));
    long group_start_jd = prev_jd;
    long i;

    for (i = 1; i < len; i++) {
        CHECK_ARRAY_MUTATION(self, len);

        VALUE curr_value = RARRAY_AREF(self, i);

        if (CLASS_OF(curr_value) != first_class) {
            rb_raise(rb_eTypeError, "All elements must be of the same type");
        }

        long curr_jd = NUM2LONG(rb_funcall(curr_value, id_jd, 0));
        CHECK_ARRAY_MUTATION(self, len);

        if (curr_jd == prev_jd + 1) {
            prev_value = curr_value;
            prev_jd = curr_jd;
        } else {
            long size = prev_jd - group_start_jd + 1;
            if (size >= min_range_size) {
                out[pos++] = rb_range_new(group_start, prev_value, 0);
            } else {
                VALUE curr = group_start;
                out[pos++] = curr;
                long j;
                for (j = 1; j < size; j++) {
                    curr = rb_funcall(curr, id_succ, 0);
                    CHECK_ARRAY_MUTATION(self, len);
                    out[pos++] = curr;
                }
            }
            group_start = curr_value;
            group_start_jd = curr_jd;
            prev_value = curr_value;
            prev_jd = curr_jd;
        }
    }

    {
        long size = prev_jd - group_start_jd + 1;
        if (size >= min_range_size) {
            out[pos++] = rb_range_new(group_start, prev_value, 0);
        } else {
            VALUE curr = group_start;
            out[pos++] = curr;
            long j;
            for (j = 1; j < size; j++) {
                curr = rb_funcall(curr, id_succ, 0);
                CHECK_ARRAY_MUTATION(self, len);
                out[pos++] = curr;
            }
        }
    }

    seal_array_len(result, out, pos);
    return result;
}

static VALUE process_generic_array(VALUE self, long len, long min_range_size, VALUE first_elem) {
    VALUE result = rb_ary_new_capa(len);
    VALUE *out = RARRAY_PTR(result);
    long pos = 0;

    VALUE group_start = first_elem;
    VALUE prev_value = first_elem;
    VALUE first_class = CLASS_OF(first_elem);
    long current_size = 1;
    long i;

    for (i = 1; i < len; i++) {
        CHECK_ARRAY_MUTATION(self, len);

        VALUE curr_value = RARRAY_AREF(self, i);

        if (CLASS_OF(curr_value) != first_class) {
            rb_raise(rb_eTypeError, "All elements must be of the same type");
        }

        VALUE succ_prev = rb_funcall(prev_value, id_succ, 0);
        CHECK_ARRAY_MUTATION(self, len);

        if (RTEST(rb_equal(curr_value, succ_prev))) {
            current_size++;
        } else {
            if (current_size >= min_range_size) {
                out[pos++] = rb_range_new(group_start, prev_value, 0);
            } else {
                VALUE curr = group_start;
                out[pos++] = curr;
                long j;
                for (j = 1; j < current_size; j++) {
                    curr = rb_funcall(curr, id_succ, 0);
                    CHECK_ARRAY_MUTATION(self, len);
                    out[pos++] = curr;
                }
            }
            group_start = curr_value;
            current_size = 1;
        }

        prev_value = curr_value;
    }

    if (current_size >= min_range_size) {
        out[pos++] = rb_range_new(group_start, prev_value, 0);
    } else {
        VALUE curr = group_start;
        out[pos++] = curr;
        long j;
        for (j = 1; j < current_size; j++) {
            curr = rb_funcall(curr, id_succ, 0);
            CHECK_ARRAY_MUTATION(self, len);
            out[pos++] = curr;
        }
    }

    seal_array_len(result, out, pos);
    return result;
}

static VALUE rb_array_group_monotonic(int argc, VALUE *argv, VALUE self) {
    long min_range_size;
    long len;
    VALUE first_elem;

    if (argc == 0) {
        min_range_size = 3;
    } else if (argc == 1) {
        min_range_size = NUM2LONG(argv[0]);
    } else {
        rb_raise(rb_eArgError, "wrong number of arguments (given %d, expected 0..1)", argc);
    }

    if (min_range_size < 1) {
        rb_raise(rb_eArgError, "min_range_size must be at least 1");
    }

    len = RARRAY_LEN(self);

    if (len == 0) {
        return rb_ary_new();
    }

    first_elem = RARRAY_AREF(self, 0);

    if (FIXNUM_P(first_elem)) {
        return process_fixnum_array(self, len, min_range_size);
    }

    if (rb_cDate != Qnil && rb_obj_is_kind_of(first_elem, rb_cDate)) {
        return process_date_array(self, len, min_range_size, first_elem);
    }

    if (!rb_respond_to(first_elem, id_succ)) {
        rb_raise(rb_eTypeError, "Elements must respond to :succ method");
    }

    return process_generic_array(self, len, min_range_size, first_elem);
}

static VALUE get_date_class(VALUE obj) {
    return rb_const_get(obj, rb_intern("Date"));
}

void Init_monotonic_grouper(void) {
    int state = 0;
    id_succ = rb_intern("succ");
    id_jd = rb_intern("jd");
    rb_mMonotonicGrouper = rb_define_module("MonotonicGrouper");
    rb_cDate = rb_protect(get_date_class, rb_cObject, &state);
    if (state != 0) {
        rb_cDate = Qnil;
        rb_set_errinfo(Qnil);
    }

    rb_define_method(rb_cArray, "group_monotonic", rb_array_group_monotonic, -1);
}
