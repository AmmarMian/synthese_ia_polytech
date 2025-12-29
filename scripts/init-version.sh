#!/bin/bash
# Initialize versioning system for LaTeX document
# This script sets up semantic versioning with git hooks

set -e  # Exit on error

# Get script directory and source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/utils.sh"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Version Tracking System Initialization ===${NC}\n"

# Check dependencies
echo "Checking dependencies..."
check_jq || exit 1
check_git_repo || exit 1
echo -e "${GREEN}✓ All dependencies satisfied${NC}\n"

# Check if already initialized
if [[ -f "$PROJECT_ROOT/versions.json" ]]; then
    echo -e "${YELLOW}Warning: versions.json already exists.${NC}"
    read -p "Do you want to reinitialize? This will backup the existing file. [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Initialization cancelled."
        exit 0
    fi
    cp "$PROJECT_ROOT/versions.json" "$PROJECT_ROOT/versions.json.backup"
    echo -e "${GREEN}✓ Backed up existing versions.json${NC}\n"
fi

# Prompt for initial version
echo "Current version.tex contains: $(cat "$PROJECT_ROOT/version.tex" | grep -o '[0-9]\+\.[0-9]\+')"
read -p "Enter initial semantic version [default: 1.0.0]: " INITIAL_VERSION
INITIAL_VERSION=${INITIAL_VERSION:-1.0.0}

# Validate version format
if ! validate_version "$INITIAL_VERSION"; then
    echo -e "${RED}Error: Invalid version format. Use semantic versioning (e.g., 1.0.0)${NC}"
    exit 1
fi

CURRENT_DATE=$(get_current_date)

# Get current commit hash (if any commits exist)
if git rev-parse HEAD >/dev/null 2>&1; then
    CURRENT_COMMIT=$(git rev-parse HEAD)
    # Get only the first line of commit message to avoid JSON issues
    COMMIT_MSG=$(git log -1 --pretty=%s)
else
    echo -e "${YELLOW}Warning: No commits found. Creating placeholder entry.${NC}"
    CURRENT_COMMIT="none"
    COMMIT_MSG="Initial version (no commit yet)"
fi

echo -e "\n${BLUE}Creating version tracking files...${NC}"

# Create versions.json
cat > "$PROJECT_ROOT/versions.json" <<EOF
{
  "current": "$INITIAL_VERSION",
  "history": [
    {
      "version": "$INITIAL_VERSION",
      "date": "$CURRENT_DATE",
      "commit": "$CURRENT_COMMIT",
      "message": "$COMMIT_MSG"
    }
  ]
}
EOF
echo -e "${GREEN}✓ Created versions.json${NC}"

# Update version.tex
cat > "$PROJECT_ROOT/version.tex" <<EOF
\def\version{$INITIAL_VERSION}
\def\versiondate{$CURRENT_DATE}
EOF
echo -e "${GREEN}✓ Updated version.tex${NC}"

# Install pre-commit hook
echo -e "\n${BLUE}Installing git hooks...${NC}"

cat > "$PROJECT_ROOT/.git/hooks/pre-commit" <<'HOOK_EOF'
#!/bin/bash
# Pre-commit hook for automatic version tracking

set -e

# Get project root and source utilities
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
SCRIPT_DIR="$PROJECT_ROOT/scripts"

if [[ ! -f "$SCRIPT_DIR/utils.sh" ]]; then
    echo "Error: utils.sh not found"
    exit 1
fi

source "$SCRIPT_DIR/utils.sh"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if versioning is initialized
if [[ ! -f "$PROJECT_ROOT/versions.json" ]]; then
    echo -e "${RED}Error: Versioning not initialized. Run: ./scripts/init-version.sh${NC}"
    exit 1
fi

# Check if version files are already staged (avoid infinite loop)
if git diff --cached --name-only | grep -q "^version\.tex$\|^versions\.json$"; then
    exit 0
fi

# Check if there are any staged changes (besides version files)
if git diff --cached --quiet --exit-code -- ':!version.tex' ':!versions.json'; then
    exit 0
fi

# Get current version
CURRENT_VERSION=$(get_current_version)
if [[ -z "$CURRENT_VERSION" ]]; then
    echo -e "${RED}Error: Could not read current version${NC}"
    exit 1
fi

# Bump patch version
NEW_VERSION=$(bump_patch "$CURRENT_VERSION")
NEW_DATE=$(get_current_date)

echo -e "${GREEN}[Version Hook] Bumping version: $CURRENT_VERSION → $NEW_VERSION${NC}"

# Update version.tex
cat > "$PROJECT_ROOT/version.tex" <<EOF
\def\version{$NEW_VERSION}
\def\versiondate{$NEW_DATE}
EOF

# Update versions.json with placeholder commit
TEMP_COMMIT="pending"
COMMIT_MSG="Version bump"

jq --arg version "$NEW_VERSION" \
   --arg date "$NEW_DATE" \
   --arg commit "$TEMP_COMMIT" \
   --arg message "$COMMIT_MSG" \
   '.current = $version | .history += [{
       version: $version,
       date: $date,
       commit: $commit,
       message: $message
   }]' "$PROJECT_ROOT/versions.json" > "$PROJECT_ROOT/versions.json.tmp"

mv "$PROJECT_ROOT/versions.json.tmp" "$PROJECT_ROOT/versions.json"

# Stage updated files
git add "$PROJECT_ROOT/version.tex" "$PROJECT_ROOT/versions.json"

echo -e "${GREEN}[Version Hook] Version files updated and staged${NC}"

exit 0
HOOK_EOF

chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"
echo -e "${GREEN}✓ Installed pre-commit hook${NC}"

# Install post-commit hook
cat > "$PROJECT_ROOT/.git/hooks/post-commit" <<'HOOK_EOF'
#!/bin/bash
# Post-commit hook to update commit hash in versions.json

# Prevent infinite loop - check if we're already amending
if [[ -n "$GIT_AMENDING" ]]; then
    exit 0
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# Check if versions.json exists and has a pending commit
if [[ ! -f "$PROJECT_ROOT/versions.json" ]]; then
    exit 0
fi

# Check if the last entry has "pending" commit
LAST_COMMIT=$(jq -r '.history[-1].commit' "$PROJECT_ROOT/versions.json" 2>/dev/null)
if [[ "$LAST_COMMIT" != "pending" ]]; then
    exit 0
fi

# Get actual commit hash
COMMIT_HASH=$(git rev-parse HEAD)

# Get commit message (first line only to avoid JSON issues)
COMMIT_MSG=$(git log -1 --pretty=%s)

# Update the last entry in history with actual commit hash and message
jq --arg commit "$COMMIT_HASH" \
   --arg message "$COMMIT_MSG" \
   '(.history[-1].commit) = $commit | (.history[-1].message) = $message' \
   "$PROJECT_ROOT/versions.json" > "$PROJECT_ROOT/versions.json.tmp"

mv "$PROJECT_ROOT/versions.json.tmp" "$PROJECT_ROOT/versions.json"

# Amend the commit with updated versions.json
git add "$PROJECT_ROOT/versions.json"
export GIT_AMENDING=1
git commit --amend --no-edit --no-verify >/dev/null 2>&1
unset GIT_AMENDING

exit 0
HOOK_EOF

chmod +x "$PROJECT_ROOT/.git/hooks/post-commit"
echo -e "${GREEN}✓ Installed post-commit hook${NC}"

echo -e "\n${GREEN}=== Initialization Complete! ===${NC}"
echo -e "Initial version: ${BLUE}$INITIAL_VERSION${NC}"
echo -e "Date: ${BLUE}$CURRENT_DATE${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the updated version.tex file"
echo "  2. View version history: ./scripts/show-versions.sh"
echo "  3. Make changes and commit - versions will auto-increment!"
echo ""
echo "Optional: Add version date to your document in main.tex:"
echo "  \\item \\textbf{Version} : V.\\version~(\\versiondate)"
