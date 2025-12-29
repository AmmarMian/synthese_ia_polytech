#!/bin/bash
# Display version history in various formats

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
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default values
FORMAT="table"
LIMIT=0
REVERSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --reverse)
            REVERSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Display version history in various formats"
            echo ""
            echo "Options:"
            echo "  --format FORMAT  Output format: table, json, or csv (default: table)"
            echo "  --limit N        Show only N most recent versions (default: all)"
            echo "  --reverse        Show oldest versions first"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Check dependencies
check_jq || exit 1

# Check if versions.json exists
if [[ ! -f "$PROJECT_ROOT/versions.json" ]]; then
    echo -e "${RED}Error: versions.json not found. Run: ./scripts/init-version.sh${NC}"
    exit 1
fi

# Get current version
CURRENT_VERSION=$(jq -r '.current' "$PROJECT_ROOT/versions.json")

# Get history
if [[ "$REVERSE" = true ]]; then
    HISTORY=$(jq -c '.history[]' "$PROJECT_ROOT/versions.json")
else
    HISTORY=$(jq -c '.history | reverse | .[]' "$PROJECT_ROOT/versions.json")
fi

# Apply limit if specified
if [[ $LIMIT -gt 0 ]]; then
    HISTORY=$(echo "$HISTORY" | head -n "$LIMIT")
fi

# Output based on format
case $FORMAT in
    json)
        # JSON format
        if [[ "$REVERSE" = true ]]; then
            jq '.history' "$PROJECT_ROOT/versions.json"
        else
            jq '.history | reverse' "$PROJECT_ROOT/versions.json"
        fi
        ;;

    csv)
        # CSV format
        echo "Version,Date,Commit,Message"
        echo "$HISTORY" | while IFS= read -r entry; do
            VERSION=$(echo "$entry" | jq -r '.version')
            DATE=$(echo "$entry" | jq -r '.date')
            COMMIT=$(echo "$entry" | jq -r '.commit')
            MESSAGE=$(echo "$entry" | jq -r '.message' | sed 's/"/""/g')
            echo "$VERSION,$DATE,$COMMIT,\"$MESSAGE\""
        done
        ;;

    table)
        # Table format (default)
        echo -e "${BOLD}Version History${NC}"
        echo "═══════════════════════════════════════════════════════════════════════════════"
        printf "%-10s %-12s %-12s %s\n" "Version" "Date" "Commit" "Message"
        echo "───────────────────────────────────────────────────────────────────────────────"

        echo "$HISTORY" | while IFS= read -r entry; do
            VERSION=$(echo "$entry" | jq -r '.version')
            DATE=$(echo "$entry" | jq -r '.date')
            COMMIT=$(echo "$entry" | jq -r '.commit')
            MESSAGE=$(echo "$entry" | jq -r '.message')

            # Shorten commit hash
            if [[ ${#COMMIT} -gt 40 ]]; then
                COMMIT_SHORT="${COMMIT:0:8}"
            elif [[ ${#COMMIT} -eq 40 ]]; then
                COMMIT_SHORT="${COMMIT:0:8}"
            else
                COMMIT_SHORT="$COMMIT"
            fi

            # Truncate message if too long
            if [[ ${#MESSAGE} -gt 50 ]]; then
                MESSAGE="${MESSAGE:0:47}..."
            fi

            # Highlight current version
            if [[ "$VERSION" == "$CURRENT_VERSION" ]]; then
                printf "${GREEN}%-10s${NC} %-12s %-12s %s\n" "$VERSION" "$DATE" "$COMMIT_SHORT" "$MESSAGE"
            else
                printf "%-10s %-12s %-12s %s\n" "$VERSION" "$DATE" "$COMMIT_SHORT" "$MESSAGE"
            fi
        done

        echo "───────────────────────────────────────────────────────────────────────────────"

        # Count total versions
        TOTAL=$(jq '.history | length' "$PROJECT_ROOT/versions.json")
        echo -e "${CYAN}Current version: ${BOLD}$CURRENT_VERSION${NC}"
        echo -e "${CYAN}Total versions: $TOTAL${NC}"
        ;;

    *)
        echo -e "${RED}Error: Invalid format. Use: table, json, or csv${NC}"
        exit 1
        ;;
esac
