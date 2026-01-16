#!/bin/bash

# Ralph CLI - A story processing tool for git repositories

set -e

# ============================================================================
# Helper Functions
# ============================================================================

# Print error message and exit
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Print usage information
print_usage() {
    echo "Usage:"
    echo "  ralph /path [--options]     Run in default mode"
    echo "  ralph --subcommand [--options]  Run in subcommand mode"
    echo ""
    echo "Default Mode Options:"
    echo "  --init     Initialize the target directory with .ralph folder"
    echo "  --story    Create a new story file in the .ralph folder"
    echo ""
    echo "For more information, see the documentation."
}

# Check if a directory is a git repository
is_git_repo() {
    local dir="$1"
    [ -d "$dir/.git" ]
}

# Find the git repository root from a given path
find_git_root() {
    local dir="$1"
    
    # Make sure we have an absolute path
    dir=$(cd "$dir" && pwd)
    
    while [ "$dir" != "/" ]; do
        if is_git_repo "$dir"; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    
    return 1
}

# Resolve and validate the target path
resolve_target_path() {
    local input_path="$1"
    local resolved_path
    
    # Resolve to absolute path
    if [[ "$input_path" = /* ]]; then
        resolved_path="$input_path"
    else
        resolved_path="$(cd "$(pwd)" && cd "$input_path" 2>/dev/null && pwd)" || \
            error_exit "Path '$input_path' does not exist or is not accessible."
    fi
    
    # Rule 1: Must be a directory and must exist
    if [ ! -d "$resolved_path" ]; then
        error_exit "Target path '$resolved_path' must be a directory and must exist."
    fi
    
    # Rule 2: Must be or be under a git repository
    local git_root
    git_root=$(find_git_root "$resolved_path") || \
        error_exit "Target path '$resolved_path' is not within a git repository."
    
    # If the path is under a git repo, use the git root as the target path
    echo "$git_root"
}

# Parse YAML header from a story file
parse_yaml_header() {
    local file="$1"
    local field="$2"
    
    # Check if file starts with ---
    if ! head -n 1 "$file" | grep -q "^---$"; then
        return 1
    fi
    
    # Extract YAML block and get the field value
    sed -n '/^---$/,/^---$/p' "$file" | grep "^${field}:" | sed "s/^${field}:[[:space:]]*//"
}

# Get story state (defaults to 'draft' if not found or invalid)
get_story_state() {
    local file="$1"
    local state
    
    state=$(parse_yaml_header "$file" "state") || state="draft"
    
    # Validate state value
    case "$state" in
        draft|feedback|complete)
            echo "$state"
            ;;
        *)
            echo "draft"
            ;;
    esac
}

# Get story title
get_story_title() {
    local file="$1"
    parse_yaml_header "$file" "title" || echo "untitled"
}

# Create a new story file with YAML header
create_story_file() {
    local ralph_dir="$1"
    local story_file
    
    if [ ! -f "$ralph_dir/story.md" ]; then
        story_file="$ralph_dir/story.md"
    else
        local epoch
        epoch=$(date +%s%3N)
        story_file="$ralph_dir/story-${epoch}.md"
    fi
    
    cat > "$story_file" << 'EOF'
---
title: Your story title
state: draft
---

## User Story



## Acceptance Criteria


EOF
    
    echo "Created new story file: $story_file"
}

# Initialize .ralph directory with default content
init_ralph_dir() {
    local target_path="$1"
    local ralph_dir="$target_path/.ralph"
    
    if [ -d "$ralph_dir" ]; then
        error_exit "Directory '$target_path' already contains a .ralph folder."
    fi
    
    # Create .ralph directory
    mkdir -p "$ralph_dir"
    
    # Create common.md
    cat > "$ralph_dir/common.md" << 'EOF'
# Common Configuration

This file contains common information valid for each story.
Content here defines the baseline for story processing.

## Project Context

<!-- Add project-specific context here -->

## Guidelines

<!-- Add processing guidelines here -->

EOF
    
    # Create initial story.md
    cat > "$ralph_dir/story.md" << 'EOF'
---
title: Your story title
state: draft
---

## User Story



## Acceptance Criteria


EOF
    
    echo "Initialized .ralph folder in: $target_path"
    echo "  Created: $ralph_dir/common.md"
    echo "  Created: $ralph_dir/story.md"
}

# Move processed story to history
move_to_history() {
    local ralph_dir="$1"
    local story_file="$2"
    local history_dir="$ralph_dir/history"
    
    # Create history directory if it doesn't exist
    mkdir -p "$history_dir"
    
    local title
    title=$(get_story_title "$story_file")
    # Sanitize title for filename
    title=$(echo "$title" | tr ' ' '-' | tr -cd '[:alnum:]-_')
    
    local timestamp
    timestamp=$(date +%Y%m%d%H%M%S)
    
    local new_name="${timestamp}-${title}.md"
    mv "$story_file" "$history_dir/$new_name"
    
    echo "Moved story to history: $history_dir/$new_name"
}

# Process a story in feedback mode
process_feedback_story() {
    local story_file="$1"
    
    echo "Processing story in feedback mode: $story_file"
    # In feedback mode, we can only modify the story file itself
    # This is a placeholder for actual feedback processing logic
    echo "Feedback processing completed for: $story_file"
}

# Process a story in complete mode
process_complete_story() {
    local ralph_dir="$1"
    local story_file="$2"
    
    echo "Processing story in complete mode: $story_file"
    # This is a placeholder for actual story processing logic
    echo "Story processing completed for: $story_file"
    
    # Move to history after successful processing
    move_to_history "$ralph_dir" "$story_file"
}

# Find and process all story files
process_stories() {
    local ralph_dir="$1"
    local common_file="$ralph_dir/common.md"
    
    # Check for common.md (baseline configuration)
    if [ -f "$common_file" ]; then
        echo "Using common configuration from: $common_file"
    fi
    
    # Find all story files
    local story_files=()
    
    if [ -f "$ralph_dir/story.md" ]; then
        story_files+=("$ralph_dir/story.md")
    fi
    
    # Find story-[epoch].md files
    while IFS= read -r -d '' file; do
        story_files+=("$file")
    done < <(find "$ralph_dir" -maxdepth 1 -name "story-*.md" -print0 2>/dev/null)
    
    if [ ${#story_files[@]} -eq 0 ]; then
        echo "No story files found in $ralph_dir"
        return 0
    fi
    
    # Process each story file based on its state
    for story_file in "${story_files[@]}"; do
        local state
        state=$(get_story_state "$story_file")
        local title
        title=$(get_story_title "$story_file")
        
        echo "Found story: '$title' (state: $state)"
        
        case "$state" in
            draft)
                echo "  Skipping: Story is in draft state"
                ;;
            feedback)
                process_feedback_story "$story_file"
                ;;
            complete)
                process_complete_story "$ralph_dir" "$story_file"
                ;;
        esac
    done
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    # Check if any arguments provided
    if [ $# -eq 0 ]; then
        print_usage
        exit 0
    fi
    
    local first_arg="$1"
    
    # Check if running in subcommand mode (first arg starts with --)
    if [[ "$first_arg" == --* ]]; then
        # Subcommand mode
        case "$first_arg" in
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                # Placeholder for other subcommands
                error_exit "Unknown subcommand: $first_arg"
                ;;
        esac
    else
        # Default mode - first argument is a path
        local target_path
        target_path=$(resolve_target_path "$first_arg")
        
        local ralph_dir="$target_path/.ralph"
        
        shift
        
        # Check for --init option first (before .ralph check)
        for arg in "$@"; do
            if [ "$arg" = "--init" ]; then
                init_ralph_dir "$target_path"
                exit 0
            fi
        done
        
        # Check for .ralph directory
        if [ ! -d "$ralph_dir" ]; then
            error_exit "Directory '$target_path' does not contain a .ralph folder. Use --init to create one."
        fi
        
        # Process options
        while [ $# -gt 0 ]; do
            case "$1" in
                --story)
                    create_story_file "$ralph_dir"
                    exit 0
                    ;;
                --help|-h)
                    print_usage
                    exit 0
                    ;;
                *)
                    error_exit "Unknown option: $1"
                    ;;
            esac
            shift
        done
        
        # Default action: process stories
        process_stories "$ralph_dir"
    fi
}

# Run main function with all arguments
main "$@"
