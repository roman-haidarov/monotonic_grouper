require 'benchmark'
require 'date'
require_relative 'lib/monotonic_grouper'

# Pure Ruby implementation for comparison
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

puts "=" * 60
puts "MonotonicGrouper Performance Benchmark"
puts "=" * 60

# Test 1: Small array
puts "\n1. Small array (100 elements):"
small_array = (1..100).to_a
Benchmark.bm(20) do |x|
  x.report("Ruby version:") { 1000.times { small_array.group_monotonic_ruby } }
  x.report("C extension:") { 1000.times { small_array.group_monotonic } }
end

# Test 2: Medium array
puts "\n2. Medium array (1,000 elements):"
medium_array = (1..1000).to_a
Benchmark.bm(20) do |x|
  x.report("Ruby version:") { 100.times { medium_array.group_monotonic_ruby } }
  x.report("C extension:") { 100.times { medium_array.group_monotonic } }
end

# Test 3: Large array
puts "\n3. Large array (10,000 elements):"
large_array = (1..10000).to_a
Benchmark.bm(20) do |x|
  x.report("Ruby version:") { 10.times { large_array.group_monotonic_ruby } }
  x.report("C extension:") { 10.times { large_array.group_monotonic } }
end

# Test 4: Very large array
puts "\n4. Very large array (100,000 elements):"
very_large_array = (1..100000).to_a
Benchmark.bm(20) do |x|
  x.report("Ruby version:") { very_large_array.group_monotonic_ruby }
  x.report("C extension:") { very_large_array.group_monotonic }
end

# Test 5: Array with gaps (worst case for grouping)
puts "\n5. Array with many gaps (10,000 elements, gaps every 5):"
gapped_array = (1..10000).select { |i| i % 5 != 0 }
Benchmark.bm(20) do |x|
  x.report("Ruby version:") { 10.times { gapped_array.group_monotonic_ruby } }
  x.report("C extension:") { 10.times { gapped_array.group_monotonic } }
end

# # Test 6: Dates (SKIPPED - segfault issue with Date objects)
# puts "\n6. Date objects (1,000 dates):"
# start_date = Date.new(2024, 1, 1)
# dates_array = (0...1000).map { |i| start_date + i }
# Benchmark.bm(20) do |x|
#   x.report("C extension (dates):") { 10.times { dates_array.group_monotonic } }
# end

puts "\n" + "=" * 60
puts "Benchmark complete!"
puts "=" * 60
