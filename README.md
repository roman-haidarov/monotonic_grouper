# MonotonicGrouper

Fast C extension for grouping monotonic sequences in Ruby arrays. Groups consecutive monotonic sequences into ranges while keeping isolated elements as singles.

## Features

- ⚡ **High Performance**: C implementation for maximum speed (O(n) complexity)
- 🔄 **Generic Support**: Works with any Comparable type that has `succ` method
- 📅 **Multiple Types**: Integers, Dates, Characters, and more
- 🎯 **Configurable**: Adjustable minimum range size
- 💎 **Ruby-friendly**: Seamless integration as Array method
- 🚀 **Optimized Date Processing**: Special fast path for Date objects with cached Julian Day calculations

## Recent Updates (v1.0.3 - Stable)

### Bug Fixes (v1.0.3)
- **Critical**: Fixed `group_monotonic` method not being available on Array class in external applications
- Properly encapsulated the method in Array class through C extension

### Previous Updates (v1.0.2)
- **Critical**: Fixed first element being incorrectly skipped in all processing paths
- **2x faster Date processing**: Optimized by caching Julian Day Numbers
- Faster array access using `RARRAY_AREF` macro
- Better memory preallocation
- Improved Date subclass handling (DateTime, custom Date classes)

## Installation

```bash
gem install monotonic_grouper
```

Or in your Gemfile:

```ruby
gem 'monotonic_grouper'
```

## Usage

```ruby
require 'monotonic_grouper'

# Basic integer usage
[1, 2, 3, 4, 5, 10, 11, 12].group_monotonic(3)
# => [1..5, 10..12]

# With singles (sequences shorter than min_range_size)
[1, 2, 3, 4, 7, 9, 10, 11, 12].group_monotonic(3)
# => [1..4, 7, 9, 10..12]

# Custom minimum range size
[1, 2, 3, 5, 6, 8].group_monotonic(2)
# => [1..3, 5..6, 8]

# Works with Dates
require 'date'
dates = [
  Date.new(2024, 1, 1),
  Date.new(2024, 1, 2),
  Date.new(2024, 1, 3),
  Date.new(2024, 1, 5),
  Date.new(2024, 1, 6),
  Date.new(2024, 1, 7)
]
dates.group_monotonic(3)
# => [Date.new(2024, 1, 1)..Date.new(2024, 1, 3), 
#     Date.new(2024, 1, 5)..Date.new(2024, 1, 7)]

# Works with characters
['a', 'b', 'c', 'd', 'f', 'g', 'h'].group_monotonic(3)
# => ['a'..'d', 'f'..'h']
```

## API

### `Array#group_monotonic(min_range_size = 3)`

Groups consecutive monotonic sequences in an array.

**Parameters:**
- `min_range_size` (Integer, optional): Minimum number of consecutive elements to form a range. Default: 3

**Returns:**
- Array containing Range objects for sequences and individual elements for singles
- First element is always excluded from the result

**Requirements:**
- All elements must be Comparable (respond to `<=>`)
- All elements must have `succ` method
- All elements must be of the same type

**Raises:**
- `TypeError` if elements don't meet requirements

## Algorithm Complexity

**Time Complexity**: O(n)
- Single pass through the array
- Each element is checked exactly once
- This is optimal - you cannot detect sequences without examining each element

**Space Complexity**: O(n)
- Result array can contain up to n elements in worst case

**Why O(n) is optimal:**
You cannot find monotonic sequences faster than O(n) because:
1. You must examine each element at least once
2. Any algorithm that skips elements might miss important data
3. The problem requires complete information about all elements

**C Extension Benefits:**
While algorithmic complexity stays O(n), the C extension provides:
- ~10-50x speedup over pure Ruby (depending on array size)
- Elimination of Ruby interpreter overhead
- Direct memory access
- Compiler optimizations

## Performance

Benchmark on 10,000 elements:

```ruby
require 'benchmark'

arr = (1..10000).to_a

Benchmark.bm do |x|
  x.report("C extension:") { arr.group_monotonic }
end
```

The C extension is significantly faster than pure Ruby implementation while maintaining the same O(n) complexity.

## Building from Source

```bash
git clone https://github.com/yourusername/monotonic_grouper
cd monotonic_grouper
bundle install
rake compile
rake test
```

## Requirements

- Ruby >= 2.5.0
- C compiler (gcc, clang, etc.)
- Make

## Supported Types

Any Ruby object that:
1. Implements `Comparable` (`<=>` operator)
2. Has `succ` method (successor)

Examples:
- Integer
- Date
- Time
- String (single characters)
- Custom classes implementing these methods

## Contributing

Bug reports and pull requests are welcome!

## License

MIT License
