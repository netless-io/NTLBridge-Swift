#!/bin/bash

# Release script for NTLBridge Swift package
# Usage: ./release.sh <version>

set -e

# Check if version parameter is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 1.0.0"
    exit 1
fi

VERSION=$1
# Validate version format (semver)
if [[ ! $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in semver format (e.g., 1.0.0)"
    exit 1
fi

echo "🚀 Starting release process for version $VERSION"

# Check if working directory is clean
if [[ -n $(git status --porcelain) ]]; then
    echo "❌ Error: Working directory is not clean. Please commit or stash changes."
    git status
    exit 1
fi

# Ensure we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ $CURRENT_BRANCH != "main" ]]; then
    echo "❌ Error: Must be on main branch. Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Ensure we're up to date with remote
echo "📦 Fetching latest changes..."
git fetch origin

if [[ -n $(git log HEAD..origin/main --oneline) ]]; then
    echo "❌ Error: Local branch is behind remote. Please pull latest changes."
    exit 1
fi

# Run tests
echo "🧪 Running tests..."
swift test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Please fix tests before releasing."
    exit 1
fi

# Build the package to ensure it compiles
echo "🔨 Building package..."
swift build
if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please fix build errors before releasing."
    exit 1
fi

# Create and push tag
echo "🏷️ Creating git tag $VERSION..."
git tag "$VERSION"
git push origin "$VERSION"