#!/bin/bash
# Shared utility functions for version management

# Parse semantic version into components (returns: major minor patch)
parse_version() {
    local version="$1"
    echo "$version" | sed -E 's/([0-9]+)\.([0-9]+)\.([0-9]+)/\1 \2 \3/'
}

# Validate semantic version format
validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 1
    fi
    return 0
}

# Get current date in YYYY-MM-DD format
get_current_date() {
    date +"%Y-%m-%d"
}

# Read current version from versions.json
get_current_version() {
    if [[ -f "versions.json" ]]; then
        jq -r '.current' versions.json 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# Bump patch version (X.Y.Z -> X.Y.Z+1)
bump_patch() {
    local version="$1"
    read -r major minor patch <<< "$(parse_version "$version")"
    echo "${major}.${minor}.$((patch + 1))"
}

# Bump minor version (X.Y.Z -> X.Y+1.0)
bump_minor() {
    local version="$1"
    read -r major minor patch <<< "$(parse_version "$version")"
    echo "${major}.$((minor + 1)).0"
}

# Bump major version (X.Y.Z -> X+1.0.0)
bump_major() {
    local version="$1"
    read -r major minor patch <<< "$(parse_version "$version")"
    echo "$((major + 1)).0.0"
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it first."
        echo "  macOS: brew install jq"
        echo "  Linux: sudo apt-get install jq  or  sudo yum install jq"
        return 1
    fi
    return 0
}

# Get project root directory
get_project_root() {
    git rev-parse --show-toplevel 2>/dev/null || pwd
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not a git repository. Please run 'git init' first."
        return 1
    fi
    return 0
}
