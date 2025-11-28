#!/bin/bash

# Ensure GITHUB_TOKEN is available
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  exit 1
fi

# Get repository name and owner
REPO_NAME=${GITHUB_REPOSITORY#*/}
OWNER=${GITHUB_REPOSITORY%/*}

# Convert to lowercase
REPO_NAME=${REPO_NAME,,}
OWNER=${OWNER,,}

echo "Fetching tags for package: $REPO_NAME in owner: $OWNER"

# Fetch versions from GHCR
# We need to look at metadata.container.tags to find the version numbers
VERSIONS_JSON=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/users/$OWNER/packages/container/$REPO_NAME/versions" \
  -q '.[] | .metadata.container.tags[]' \
  --paginate 2>/dev/null) || {
    VERSIONS_JSON=$(gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/orgs/$OWNER/packages/container/$REPO_NAME/versions" \
      -q '.[] | .metadata.container.tags[]' \
      --paginate 2>/dev/null)
}

# If no versions found, default to 1.0.0
if [ -z "$VERSIONS_JSON" ]; then
  echo "No tags found in registry. Defaulting to 1.0.0"
  echo "NEXT_VERSION=1.0.0" >> $GITHUB_ENV
  echo "::set-output name=version::1.0.0"
  exit 0
fi

# Filter for tags that match our version pattern (X.Y.Z)
# We ignore 'latest' and anything that doesn't look like a number
# We sort by version (sort -V) and take the last one
LATEST_TAG=$(echo "$VERSIONS_JSON" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1)

if [ -z "$LATEST_TAG" ]; then
  echo "No valid version tags found. Defaulting to 1.0.0"
  echo "NEXT_VERSION=1.0.0" >> $GITHUB_ENV
  echo "::set-output name=version::1.0.0"
  exit 0
fi

echo "Latest Registry Tag: $LATEST_TAG"

# Split into major, minor, patch
IFS='.' read -r -a parts <<< "$LATEST_TAG"
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
