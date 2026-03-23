require 'benchmark'
require 'date'
require_relative 'lib/monotonic_grouper'

class Array
  def group_monotonic_ruby(min_range_size = 3)
    return [] if empty?

    first_elem = first
    first_type = first_elem.class
    return nil unless first_type == Integer || first_type == Date

    result = []
    current_group = [first_elem]
    prev_value = first_elem
    current_size = 1

    each do |curr|
      return unless curr.is_a?(first_type)

      if curr == prev_value + 1
        current_group << curr
        current_size += 1
      else
        if current_size >= min_range_size
          result << (current_group[0]..current_group[-1])
        else
          result.push(*current_group)
        end
        current_group = [curr]
        current_size = 1
      end

      prev_value = curr
    end

    if current_size >= min_range_size
      result << (current_group[0]..current_group[-1])
    else
      result.push(*current_group)
    end

    result[1..]
  end
end

def mem_kb
  `ps -o rss= -p #{$$}`.strip.to_i
end

def run_bench(label, iterations, &block)
  # warmup
  3.times { block.call }

  # with GC
  GC.start
  GC.compact if GC.respond_to?(:compact)
  gc_before = GC.stat[:total_allocated_objects]
  mem_before = mem_kb
  time_with_gc = Benchmark.realtime { iterations.times { block.call } }
  gc_after = GC.stat[:total_allocated_objects]
  mem_after = mem_kb
  allocs = gc_after - gc_before

  # without GC
  GC.start
  GC.compact if GC.respond_to?(:compact)
  GC.disable
  time_no_gc = Benchmark.realtime { iterations.times { block.call } }
  GC.enable
  GC.start

  gc_overhead = time_with_gc > 0 ? ((time_with_gc - time_no_gc) / time_with_gc * 100) : 0

  printf "  %-28s %10.6f s  %10.6f s  %6.1f%%  %12d  %+6d KB\n",
         label, time_with_gc, time_no_gc, gc_overhead, allocs, mem_after - mem_before
end

def section(title)
  puts
  puts "-" * 95
  puts title
  puts "-" * 95
  printf "  %-28s %10s     %10s     %6s  %12s  %8s\n",
         "", "with GC", "no GC", "GC %", "allocs", "mem"
  puts "  " + "-" * 91
end

puts "=" * 95
puts "MonotonicGrouper Benchmark — Ruby #{RUBY_VERSION} (#{RUBY_PLATFORM})"
puts "=" * 95

# --- Fixnum: continuous (best case — one Range) ---

section "1. Fixnum continuous (best case, single Range output)"

[100, 1_000, 10_000, 100_000, 1_000_000].each do |n|
  arr = (1..n).to_a
  iters = [1_000_000 / n, 1].max
  run_bench("Ruby    #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic_ruby }
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic }
end

# --- Fixnum: gaps every 3 (many small groups) ---

section "2. Fixnum gaps every 3 (worst case, many flushes)"

[1_000, 10_000, 100_000].each do |n|
  arr = (1..n).reject { |i| i % 3 == 0 }
  iters = [100_000 / n, 1].max
  run_bench("Ruby    #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic_ruby }
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic }
end

# --- Fixnum: gaps every 100 (mixed) ---

section "3. Fixnum gaps every 100 (mixed groups)"

[10_000, 100_000].each do |n|
  arr = (1..n).reject { |i| i % 100 == 0 }
  iters = [100_000 / n, 1].max
  run_bench("Ruby    #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic_ruby }
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic }
end

# --- Fixnum: all singletons (every element is a gap) ---

section "4. Fixnum all singletons (every element isolated)"

[1_000, 10_000, 100_000].each do |n|
  arr = (1..n).map { |i| i * 3 }
  iters = [100_000 / n, 1].max
  run_bench("Ruby    #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic_ruby }
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic }
end

# --- Date path ---

section "5. Date objects (continuous)"

[100, 500, 1_000].each do |n|
  start_date = Date.new(2024, 1, 1)
  dates = (0...n).map { |i| start_date + i }
  iters = [10_000 / n, 1].max
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { dates.group_monotonic }
end

# --- Date with gaps ---

section "6. Date objects (gaps every 5)"

[100, 500, 1_000].each do |n|
  start_date = Date.new(2024, 1, 1)
  dates = (0...n).map { |i| start_date + i }.reject.with_index { |_, i| i % 5 == 0 }
  iters = [10_000 / n, 1].max
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { dates.group_monotonic }
end

# --- String (generic path) ---

section "7. String generic path (single-char sequences)"

["a".."z", "a".."zz"].each do |range|
  arr = range.to_a
  n = arr.size
  iters = [10_000 / n, 1].max
  run_bench("C ext   #{n.to_s.rjust(10)} x#{iters}", iters) { arr.group_monotonic }
end

# --- min_range_size impact ---

section "8. min_range_size impact (100K continuous)"

arr = (1..100_000).to_a
[1, 2, 3, 5, 10, 100].each do |mrs|
  run_bench("C ext   mrs=#{mrs.to_s.ljust(4)} 100K x1", 1) { arr.group_monotonic(mrs) }
end

# --- Throughput summary ---

puts
puts "=" * 95
puts "Throughput summary (elements/sec, no GC)"
puts "=" * 95

{
  "Fixnum continuous 1M" => [(1..1_000_000).to_a, 3],
  "Fixnum gaps/3    100K" => [(1..100_000).reject { |i| i % 3 == 0 }, 3],
  "Fixnum singletons 100K" => [(1..100_000).map { |i| i * 3 }, 3],
}.each do |label, (arr, iters)|
  GC.start
  GC.disable
  t = Benchmark.realtime { iters.times { arr.group_monotonic } }
  GC.enable
  eps = (arr.size * iters) / t
  printf "  %-30s %12.1f M elem/sec\n", label, eps / 1_000_000.0
end

puts
puts "=" * 95
puts "Benchmark complete!"
puts "=" * 95
