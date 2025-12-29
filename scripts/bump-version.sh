#!/bin/bash
# Bump version and update tracking files
# Can be used for manual version bumps (minor, major)

set -e

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
BUMP_TYPE="patch"
DRY_RUN=false
COMMIT_HASH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            BUMP_TYPE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --commit-hash)
            COMMIT_HASH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --type TYPE        Version bump type: patch, minor, or major (default: patch)"
            echo "  --dry-run          Show what would change without modifying files"
            echo "  --commit-hash HASH Git commit hash (for hook usage)"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Validate bump type
if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo -e "${RED}Error: Invalid bump type. Use: patch, minor, or major${NC}"
    exit 1
fi

# Check dependencies
check_jq || exit 1

# Check if versions.json exists
if [[ ! -f "$PROJECT_ROOT/versions.json" ]]; then
    echo -e "${RED}Error: versions.json not found. Run: ./scripts/init-version.sh${NC}"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(get_current_version)
if [[ -z "$CURRENT_VERSION" ]]; then
    echo -e "${RED}Error: Could not read current version from versions.json${NC}"
    exit 1
fi

# Calculate new version
case $BUMP_TYPE in
    patch)
        NEW_VERSION=$(bump_patch "$CURRENT_VERSION")
        ;;
    minor)
        NEW_VERSION=$(bump_minor "$CURRENT_VERSION")
        ;;
    major)
        NEW_VERSION=$(bump_major "$CURRENT_VERSION")
        ;;
esac

NEW_DATE=$(get_current_date)

# Dry run mode
if [[ "$DRY_RUN" = true ]]; then
    echo -e "${BLUE}Dry run mode:${NC}"
    echo "Current version: $CURRENT_VERSION"
    echo "New version: $NEW_VERSION"
    echo "Date: $NEW_DATE"
    echo "Bump type: $BUMP_TYPE"
    exit 0
fi

echo -e "${BLUE}Bumping version: $CURRENT_VERSION → $NEW_VERSION (${BUMP_TYPE})${NC}"

# Create backups
cp "$PROJECT_ROOT/version.tex" "$PROJECT_ROOT/version.tex.backup" 2>/dev/null || true
cp "$PROJECT_ROOT/versions.json" "$PROJECT_ROOT/versions.json.backup" 2>/dev/null || true

# Update version.tex
cat > "$PROJECT_ROOT/version.tex" <<EOF
\def\version{$NEW_VERSION}
\def\versiondate{$NEW_DATE}
EOF

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to update version.tex${NC}"
    # Restore backup
    mv "$PROJECT_ROOT/version.tex.backup" "$PROJECT_ROOT/version.tex" 2>/dev/null || true
    exit 1
fi

echo -e "${GREEN}✓ Updated version.tex${NC}"

# Update versions.json
# Use commit hash if provided, otherwise use placeholder
COMMIT="${COMMIT_HASH:-pending}"
COMMIT_MSG="Manual $BUMP_TYPE version bump"

jq --arg version "$NEW_VERSION" \
   --arg date "$NEW_DATE" \
   --arg commit "$COMMIT" \
   --arg message "$COMMIT_MSG" \
   '.current = $version | .history += [{
       version: $version,
       date: $date,
       commit: $commit,
       message: $message
   }]' "$PROJECT_ROOT/versions.json" > "$PROJECT_ROOT/versions.json.tmp"

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Error: Failed to update versions.json${NC}"
    # Restore backups
    mv "$PROJECT_ROOT/version.tex.backup" "$PROJECT_ROOT/version.tex" 2>/dev/null || true
    mv "$PROJECT_ROOT/versions.json.backup" "$PROJECT_ROOT/versions.json" 2>/dev/null || true
    exit 1
fi

mv "$PROJECT_ROOT/versions.json.tmp" "$PROJECT_ROOT/versions.json"
echo -e "${GREEN}✓ Updated versions.json${NC}"

# Clean up backups
rm -f "$PROJECT_ROOT/version.tex.backup" "$PROJECT_ROOT/versions.json.backup"

echo -e "${GREEN}Version bump complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the changes: git diff version.tex versions.json"
echo "  2. Stage the files: git add version.tex versions.json"
echo "  3. Commit: git commit -m \"Release v$NEW_VERSION: ...\""
echo ""
echo "Note: The pre-commit hook will skip version bumping since these files are already staged."
