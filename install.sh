#!/bin/bash

# Ralph CLI Installer
# Downloads and installs Ralph CLI from the latest GitHub release

set -e

# ============================================================================
# Configuration
# ============================================================================

REPO_OWNER="markusheiliger"
REPO_NAME="ralph"
INSTALL_BASE="$HOME/.local/share/ralph"
BIN_DIR="$HOME/.local/bin"
INSTALL_PREVIEW=false

# ============================================================================
# Helper Functions
# ============================================================================

# Print colored output
info() {
    echo -e "\033[1;34m[INFO]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
    exit 1
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect package manager and install a package
install_package() {
    local package="$1"
    
    info "Installing $package..."
    
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y "$package"
    elif command_exists dnf; then
        sudo dnf install -y "$package"
    elif command_exists yum; then
        sudo yum install -y "$package"
    elif command_exists pacman; then
        sudo pacman -Sy --noconfirm "$package"
    elif command_exists apk; then
        sudo apk add --no-cache "$package"
    elif command_exists zypper; then
        sudo zypper install -y "$package"
    elif command_exists brew; then
        brew install "$package"
    else
        error "Could not detect package manager. Please install $package manually."
    fi
    
    if ! command_exists "$package"; then
        error "Failed to install $package."
    fi
    
    success "$package installed successfully."
}

# Get the latest stable release version from GitHub
get_latest_release_version() {
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
    
    if command_exists curl; then
        curl -fsSL "$api_url" | jq -r '.tag_name'
    elif command_exists wget; then
        wget -qO- "$api_url" | jq -r '.tag_name'
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Get the latest preview release version from GitHub
get_latest_preview_version() {
    local api_url="https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases"
    
    if command_exists curl; then
        curl -fsSL "$api_url" | jq -r '.[0].tag_name'
    elif command_exists wget; then
        wget -qO- "$api_url" | jq -r '.[0].tag_name'
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Download a file
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -fsSL "$url" -o "$output"
    elif command_exists wget; then
        wget -qO "$output" "$url"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# ============================================================================
# Main Installation Logic
# ============================================================================

main() {
    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            --preview)
                INSTALL_PREVIEW=true
                shift
                ;;
            --help|-h)
                echo "Usage: install.sh [--preview]"
                echo ""
                echo "Options:"
                echo "  --preview    Install the latest preview release instead of stable"
                echo "  --help, -h   Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done

    info "Ralph CLI Installer"
    echo ""
    
    # Check and install required dependencies
    if ! command_exists curl && ! command_exists wget; then
        info "Neither curl nor wget found. Installing curl..."
        install_package curl
    fi
    
    if ! command_exists jq; then
        info "jq not found. Installing jq..."
        install_package jq
    fi
    
    # Get the latest version
    if [ "$INSTALL_PREVIEW" = true ]; then
        info "Fetching latest preview release information..."
        local version
        version=$(get_latest_preview_version)
    else
        info "Fetching latest stable release information..."
        local version
        version=$(get_latest_release_version)
    fi
    
    if [ -z "$version" ]; then
        error "Could not determine the latest version. Please check your internet connection."
    fi
    
    # Remove 'v' prefix if present for directory naming
    local version_clean="${version#v}"
    
    info "Latest version: $version"
    
    # Create installation directories
    local version_dir="$INSTALL_BASE/$version_clean"
    
    if [ -d "$version_dir" ]; then
        info "Version $version_clean is already installed."
    else
        info "Installing version $version_clean..."
        mkdir -p "$version_dir"
        
        # Construct download URL for the tarball
        local download_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${version}/ralph-${version_clean}.tar.gz"
        local tmp_file="/tmp/ralph-${version_clean}.tar.gz"
        
        info "Downloading from: $download_url"
        download_file "$download_url" "$tmp_file"
        
        # Extract the tarball
        info "Extracting..."
        tar -xzf "$tmp_file" -C "$version_dir"
        rm -f "$tmp_file"
        
        # Make the script executable
        chmod +x "$version_dir/ralph.sh"
        
        success "Version $version_clean installed to $version_dir"
    fi
    
    # Update the 'current' symlink
    info "Setting version $version_clean as current..."
    ln -sfn "$version_dir" "$INSTALL_BASE/current"
    
    # Create bin directory if it doesn't exist
    mkdir -p "$BIN_DIR"
    
    # Create symlink in user's local bin
    ln -sfn "$INSTALL_BASE/current/ralph.sh" "$BIN_DIR/ralph"
    
    success "Ralph CLI installed successfully!"
    echo ""
    info "Installation location: $INSTALL_BASE/current"
    info "Binary symlink: $BIN_DIR/ralph"
    echo ""
    
    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "\033[1;33m[WARNING]\033[0m $BIN_DIR is not in your PATH."
        echo ""
        echo "Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    else
        info "You can now run 'ralph' from anywhere!"
    fi
}

# Run the installer
main "$@"
