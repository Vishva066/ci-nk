#!/bin/bash

# Fetch all tags
git fetch --tags

# Get the latest tag that looks like a version number (ci-vX.Y.Z)
# If no tag exists, default to 1.0.0
LATEST_TAG=$(git tag -l "ci-v*" | sort -V | tail -n1)

if [ -z "$LATEST_TAG" ]; then
  echo "No tags found. Defaulting to 1.0.0"
  echo "NEXT_VERSION=1.0.0" >> $GITHUB_ENV
  echo "::set-output name=version::1.0.0"
  exit 0
fi

# Remove the 'ci-v' prefix
VERSION=${LATEST_TAG#ci-v}

# Split into major, minor, patch
IFS='.' read -r -a parts <<< "$VERSION"
MAJOR=${parts[0]}
MINOR=${parts[1]}
PATCH=${parts[2]}

echo "Current Version: $MAJOR.$MINOR.$PATCH"

# Increment logic
PATCH=$((PATCH + 1))

if [ "$PATCH" -gt 9 ]; then
  PATCH=0
  MINOR=$((MINOR + 1))
fi

if [ "$MINOR" -gt 9 ]; then
  MINOR=0
  MAJOR=$((MAJOR + 1))
fi

NEXT_VERSION="$MAJOR.$MINOR.$PATCH"
echo "Next Version: $NEXT_VERSION"

# Set output for GitHub Actions
echo "NEXT_VERSION=$NEXT_VERSION" >> $GITHUB_ENV
echo "::set-output name=version::$NEXT_VERSION"
