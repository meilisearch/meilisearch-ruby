#!/bin/sh

# Checking if current branch is master
current_branch=${GITHUB_REF}
if [ "$current_branch" != 'master' ]; then
  echo "Error: the current branch must be master."
  echo "Current branch: $current_branch"
  exit 1
fi

# Checking if current tag matches the package version
current_tag=$(git describe --tag | tr -d 'v')
file_tag=$(grep 'VERSION = ' lib/meilisearch/version.rb | cut -d "=" -f 2- | tr -d ' ' | tr -d \')
if [ "$current_tag" != "$file_tag" ]; then
  echo "Error: the current tag does not match the version in package file(s)."
  echo "$current_tag vs $file_tag"
  exit 1
fi

echo 'OK'
exit 0
