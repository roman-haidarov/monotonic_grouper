require_relative 'monotonic_grouper/version'

# Load the compiled extension (.so on Linux, .bundle on macOS)
begin
  require 'monotonic_grouper/monotonic_grouper'
rescue LoadError
  # Fallback for different extension names
  ext_dir = File.expand_path('../monotonic_grouper', __FILE__)
  if File.exist?(File.join(ext_dir, 'monotonic_grouper.bundle'))
    require File.join(ext_dir, 'monotonic_grouper.bundle')
  elsif File.exist?(File.join(ext_dir, 'monotonic_grouper.so'))
    require File.join(ext_dir, 'monotonic_grouper.so')
  else
    raise LoadError, "Could not find compiled extension"
  end
end
