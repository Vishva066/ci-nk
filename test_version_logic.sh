#!/bin/bash

# Setup
TEST_DIR=$(mktemp -d)
cp .github/scripts/calculate_version.sh $TEST_DIR/
cd $TEST_DIR
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Helper function
run_test() {
    TAG=$1
    EXPECTED=$2
    
    # Clear previous tags
    git tag | xargs git tag -d > /dev/null 2>&1
    
    if [ -n "$TAG" ]; then
        git commit --allow-empty -m "commit for $TAG" > /dev/null
        git tag $TAG
    fi
    
    # Capture output
    OUTPUT=$(./calculate_version.sh)
    NEXT_VERSION=$(echo "$OUTPUT" | grep "Next Version:" | awk '{print $3}')
    
    if [ "$NEXT_VERSION" == "$EXPECTED" ]; then
        echo "PASS: $TAG -> $EXPECTED"
    else
        echo "FAIL: $TAG -> Expected $EXPECTED, got $NEXT_VERSION"
    fi
}

echo "Running Tests..."

# Test 1: No tags
run_test "" "1.0.0"

# Test 2: Normal increment
run_test "v1.0.0" "1.0.1"

# Test 3: Patch rollover
run_test "v1.0.9" "1.1.0"

# Test 4: Minor rollover
run_test "v1.9.9" "2.0.0"

# Test 5: Mixed tags (should pick highest)
git tag v0.9.9
run_test "v1.0.5" "1.0.6"

# Cleanup
rm -rf $TEST_DIR
