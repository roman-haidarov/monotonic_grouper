# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-03-23

### Performance Improvements
- **Major Algorithm Optimization**: Substantial improvements to core grouping algorithm with better memory management and processing flow
- **54% faster** continuous sequence processing: 1244.8M → 1916.9M elem/sec
- **146% faster** worst-case scenario (gaps every 3): 166.8M → 409.8M elem/sec  
- **107% faster** singleton processing: 197.2M → 408.7M elem/sec
- Optimized memory allocation patterns reducing GC overhead
- Enhanced benchmark suite with more comprehensive performance metrics

### Technical Details
- Improved C extension implementation for better cache locality
- Reduced function call overhead in tight loops
- Better handling of edge cases in grouping logic
- Enhanced min_range_size parameter processing efficiency

## [1.0.3] - 2026-02-13

### Fixed
- **Critical Bug**: Fixed `group_monotonic` method not being available on Array class in external applications
- Properly encapsulated the method in Array class through C extension using `rb_define_method`

## [1.0.2] - 2026-02-13

### Fixed
- **Critical Bug**: Fixed first element being skipped in all processing paths (integer, date, generic)
- Fixed incorrect loop initialization that started from index 2 instead of index 1

### Performance Improvements
- **Date Processing**: Optimized Date path by caching previous Julian Day Number (jd), reducing rb_funcall calls from 2 to 1 per iteration (~2x faster for Date arrays)
- Replaced `rb_ary_entry` with faster `RARRAY_AREF` macro for direct array access
- Changed from `rb_ary_new2` to `rb_ary_new_capa` for better memory preallocation
- Removed unused `id_ajd` variable

### Changed
- Improved Date class checking using `rb_obj_is_kind_of` instead of direct class comparison (now properly handles Date subclasses and DateTime)

## [1.0.0] - Initial Release

### Added
- Initial release of MonotonicGrouper
- High-performance C extension for grouping monotonic sequences
- Support for Integer and Date arrays
- Configurable minimum range size parameter
- Comprehensive test suite and benchmarks
