#!/bin/bash
set -e

echo "Building FastBloomFilter..."
echo ""

# Clean
echo "Cleaning..."
rm -f *.gem
rm -rf lib/monotonic_grouper/*.{so,bundle}
cd ext/monotonic_grouper && make clean 2>/dev/null || true && cd ../..

# Compile
echo "Compiling C extension..."
cd ext/monotonic_grouper
ruby extconf.rb
make
cd ../..

# Copy (detect .so or .bundle)
echo "Copying library..."
mkdir -p lib/monotonic_grouper
if [ -f ext/monotonic_grouper/monotonic_grouper.bundle ]; then
    cp ext/monotonic_grouper/monotonic_grouper.bundle lib/monotonic_grouper/
    echo "Copied .bundle file (macOS)"
elif [ -f ext/monotonic_grouper/monotonic_grouper.so ]; then
    cp ext/monotonic_grouper/monotonic_grouper.so lib/monotonic_grouper/
    echo "Copied .so file (Linux)"
else
    echo "Error: No compiled extension found!"
    exit 1
fi

# Test (avoid Rails plugin conflicts)
echo "Running tests..."
ruby -I lib test/monotonic_grouper_test.rb

# Build gem
echo "Building gem..."
gem build monotonic_grouper.gemspec

echo ""
echo "Done! Gem: monotonic_grouper-1.0.0.gem"
echo ""
echo "To test manually:"
echo "  ruby demo.rb"
echo ""
echo "To install:"
echo "  gem install monotonic_grouper-1.0.0.gem"
