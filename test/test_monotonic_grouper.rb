require 'minitest/autorun'
require 'date'
require_relative '../lib/monotonic_grouper'

class MonotonicGrouperTest < Minitest::Test
  def test_empty_array
    assert_equal [], [].group_monotonic
  end

  def test_integers_basic
    arr = [1, 2, 3, 4, 5, 10, 11, 12]
    result = arr.group_monotonic(3)
    assert_equal 2, result.length
    assert_equal (2..5), result[0]
    assert_equal (10..12), result[1]
  end

  def test_integers_with_singles
    arr = [1, 2, 3, 4, 7, 9, 10, 11, 12]
    result = arr.group_monotonic(3)
    assert_equal 4, result.length
    assert_equal (2..4), result[0]
    assert_equal 7, result[1]
    assert_equal 9, result[2]
    assert_equal (10..12), result[3]
  end

  def test_min_range_size_2
    arr = [1, 2, 3, 5, 6, 8]
    result = arr.group_monotonic(2)
    assert_equal 3, result.length
    assert_equal (2..3), result[0]
    assert_equal (5..6), result[1]
    assert_equal 8, result[2]
  end

  def test_no_sequences
    arr = [1, 3, 5, 7, 9]
    result = arr.group_monotonic(3)
    assert_equal 4, result.length
    assert result.all? { |x| x.is_a?(Integer) }
  end

  def test_all_sequence
    arr = [1, 2, 3, 4, 5, 6, 7, 8]
    result = arr.group_monotonic(3)
    assert_equal 1, result.length
    assert_equal (2..8), result[0]
  end

  def test_dates
    dates = [
      Date.new(2024, 1, 1),
      Date.new(2024, 1, 2),
      Date.new(2024, 1, 3),
      Date.new(2024, 1, 5),
      Date.new(2024, 1, 6),
      Date.new(2024, 1, 7),
      Date.new(2024, 1, 8)
    ]

    result = dates.group_monotonic(3)
    assert_equal 2, result.length
    assert_equal (Date.new(2024, 1, 2)..Date.new(2024, 1, 3)), result[0]
    assert_equal (Date.new(2024, 1, 5)..Date.new(2024, 1, 8)), result[1]
  end

  def test_characters
    # Characters also support succ and are Comparable
    chars = ['a', 'b', 'c', 'd', 'f', 'g', 'h']
    result = chars.group_monotonic(3)
    assert_equal 2, result.length
    assert_equal ('b'..'d'), result[0]
    assert_equal ('f'..'h'), result[1]
  end

  def test_first_element_removed
    # Test that first element is removed (as per Ruby version)
    arr = [1, 2, 3, 4]
    result = arr.group_monotonic(3)
    # Should not include 1
    assert_equal 1, result.length
    assert_equal (2..4), result[0]
  end

  def test_invalid_type_error
    arr = [1, 2, "string", 4]

    assert_raises(TypeError) do
      arr.group_monotonic
    end
  end

  def test_performance_large_array
    # Test with large array
    arr = (1..10000).to_a
    start_time = Time.now
    result = arr.group_monotonic(3)
    end_time = Time.now
    # Should complete quickly
    assert (end_time - start_time) < 0.1, "Should process 10k elements quickly"
    # Should return one big range (minus first element)
    assert_equal 1, result.length
    assert_equal (2..10000), result[0]
  end

  def test_default_min_range_size
    arr = [1, 2, 3, 4, 5]
    result = arr.group_monotonic
    # Default should be 3
    assert_equal 1, result.length
    assert_equal (2..5), result[0]
  end
end
