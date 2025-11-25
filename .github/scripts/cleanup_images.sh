#!/bin/bash

# Ensure GITHUB_TOKEN is available
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN is not set."
  exit 1
fi

# Get repository name and owner from the environment variable
REPO_NAME=${GITHUB_REPOSITORY#*/}
OWNER=${GITHUB_REPOSITORY%/*}

# Convert to lowercase
REPO_NAME=${REPO_NAME,,}
OWNER=${OWNER,,}

echo "Cleaning up old images for package: $REPO_NAME in owner: $OWNER"

# Fetch all versions of the container package
# We try fetching for a user first, then fallback to an organization
VERSIONS=$(gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/users/$OWNER/packages/container/$REPO_NAME/versions" \
  -q '.[] | {id: .id, name: .name, created_at: .created_at}' \
  --paginate) || {
    VERSIONS=$(gh api \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "/orgs/$OWNER/packages/container/$REPO_NAME/versions" \
      -q '.[] | {id: .id, name: .name, created_at: .created_at}' \
      --paginate)
}

if [ -z "$VERSIONS" ]; then
  echo "No versions found or failed to fetch versions."
  exit 0
fi

# Get IDs of versions to delete
# We skip the first 3 (latest ones) and select the rest
IDS_TO_DELETE=$(echo "$VERSIONS" | jq -r '.[3:] | .[].id')

if [ -z "$IDS_TO_DELETE" ]; then
  echo "No versions to delete. Total versions <= 3."
  exit 0
fi

# Loop through the IDs and delete them
for ID in $IDS_TO_DELETE; do
  echo "Deleting version ID: $ID"
  gh api \
    --method DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/users/$OWNER/packages/container/$REPO_NAME/versions/$ID" || \
  gh api \
    --method DELETE \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "/orgs/$OWNER/packages/container/$REPO_NAME/versions/$ID"
done

echo "Cleanup complete."
