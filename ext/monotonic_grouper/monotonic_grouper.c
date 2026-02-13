#include <ruby.h>

#ifndef RB_BIGNUM_TYPE_P
#define RB_BIGNUM_TYPE_P(obj) (RB_TYPE_P((obj), T_BIGNUM))
#endif

static VALUE rb_mMonotonicGrouper;
static ID id_succ;
static ID id_eq;

static inline int
is_next_integer(VALUE a, VALUE b)
{
    if (FIXNUM_P(a) && FIXNUM_P(b)) {
        long av = FIX2LONG(a);
        long bv = FIX2LONG(b);
        return bv == av + 1;
    }
    return 0;
}

static inline int
is_next_in_sequence_generic(VALUE a, VALUE b)
{
    VALUE succ_a = rb_funcall(a, id_succ, 0);
    return RTEST(rb_funcall(b, id_eq, 1, succ_a));
}

static void
add_group_to_result_integer(VALUE result, VALUE group_start, VALUE group_end, long size, long min_range_size)
{
    if (size >= min_range_size) {
        VALUE range = rb_range_new(group_start, group_end, 0);
        rb_ary_push(result, range);
    } else {
        long j;
        long start_val = FIX2LONG(group_start);
        for (j = 0; j < size; j++) {
            rb_ary_push(result, LONG2FIX(start_val + j));
        }
    }
}

static void
add_group_to_result_generic(VALUE result, VALUE group_start, VALUE group_end, long size, long min_range_size)
{
    if (size >= min_range_size) {
        VALUE range = rb_range_new(group_start, group_end, 0);
        rb_ary_push(result, range);
    } else {
        long j;
        VALUE curr = group_start;
        rb_ary_push(result, curr);
        for (j = 1; j < size; j++) {
            curr = rb_funcall(curr, id_succ, 0);
            rb_ary_push(result, curr);
        }
    }
}

static VALUE
process_integer_array(VALUE self, long len, long min_range_size)
{
    VALUE result = rb_ary_new2(len / 2);
    VALUE first_elem = rb_ary_entry(self, 0);
    VALUE group_start = first_elem;
    VALUE group_end = first_elem;
    VALUE prev_value = first_elem;
    long current_size = 1;
    long i;

    for (i = 1; i < len; i++) {
        VALUE curr_value = rb_ary_entry(self, i);

        if (!FIXNUM_P(curr_value) && !RB_BIGNUM_TYPE_P(curr_value)) {
            rb_raise(rb_eTypeError, "All elements must be of the same type");
        }

        if (is_next_integer(prev_value, curr_value)) {
            group_end = curr_value;
            current_size++;
        } else {
            add_group_to_result_integer(result, group_start, group_end, current_size, min_range_size);
            group_start = curr_value;
            group_end = curr_value;
            current_size = 1;
        }

        prev_value = curr_value;
    }

    add_group_to_result_integer(result, group_start, group_end, current_size, min_range_size);

    return result;
}

static VALUE
process_generic_array(VALUE self, long len, long min_range_size, VALUE first_elem)
{
    VALUE result = rb_ary_new2(len / 2);
    VALUE group_start = first_elem;
    VALUE group_end = first_elem;
    VALUE prev_value = first_elem;
    VALUE first_class = CLASS_OF(first_elem);
    long current_size = 1;
    long i;

    for (i = 1; i < len; i++) {
        VALUE curr_value = rb_ary_entry(self, i);
        if (CLASS_OF(curr_value) != first_class) {
            rb_raise(rb_eTypeError, "All elements must be of the same type");
        }

        if (is_next_in_sequence_generic(prev_value, curr_value)) {
            group_end = curr_value;
            current_size++;
        } else {
            add_group_to_result_generic(result, group_start, group_end, current_size, min_range_size);
            group_start = curr_value;
            group_end = curr_value;
            current_size = 1;
        }

        prev_value = curr_value;
    }

    add_group_to_result_generic(result, group_start, group_end, current_size, min_range_size);

    return result;
}

static VALUE
rb_array_group_monotonic(int argc, VALUE *argv, VALUE self)
{
    VALUE min_range_size_val;
    long min_range_size;
    long len;
    VALUE first_elem;

    rb_scan_args(argc, argv, "01", &min_range_size_val);
    min_range_size = NIL_P(min_range_size_val) ? 3 : NUM2LONG(min_range_size_val);

    if (min_range_size < 1) {
        rb_raise(rb_eArgError, "min_range_size must be at least 1");
    }

    len = RARRAY_LEN(self);

    if (len == 0) {
        return rb_ary_new();
    }

    first_elem = rb_ary_entry(self, 0);

    if (FIXNUM_P(first_elem) || RB_BIGNUM_TYPE_P(first_elem)) {
        return process_integer_array(self, len, min_range_size);
    }

    if (!rb_respond_to(first_elem, id_succ)) {
        rb_raise(rb_eTypeError, "Elements must respond to :succ method");
    }

    return process_generic_array(self, len, min_range_size, first_elem);
}

void
Init_monotonic_grouper(void)
{
    id_succ = rb_intern("succ");
    id_eq = rb_intern("==");
    rb_mMonotonicGrouper = rb_define_module("MonotonicGrouper");
    rb_define_method(rb_cArray, "group_monotonic", rb_array_group_monotonic, -1);
}
