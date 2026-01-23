#!/bin/bash
# =============================================================================
# GSTREAMER CODEC INSTALLATION SCRIPT
# =============================================================================
#
# This script automatically installs comprehensive GStreamer codec support
# for the My Browser project, including hardware acceleration drivers.
#
# Supports: Arch Linux, Fedora, Ubuntu/Debian
#
# Usage: ./install-gstreamer-codecs.sh [--check-only]
#
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "💡 $1"
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
}

# Check if package is installed
is_installed() {
    case "$DISTRO" in
        arch|manjaro)
            pacman -Qi "$1" &> /dev/null
            ;;
        fedora|rhel|centos)
            rpm -q "$1" &> /dev/null
            ;;
        ubuntu|debian)
            dpkg -l "$1" &> /dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# MAIN INSTALLATION
# =============================================================================

print_header "GStreamer Codec Installation for My Browser"
echo ""

# Detect distribution
detect_distro
print_info "Detected distribution: $DISTRO"
echo ""

# Check-only mode
if [ "$1" = "--check-only" ]; then
    print_header "Checking Installed Packages (Check-Only Mode)"
    CHECK_ONLY=true
else
    CHECK_ONLY=false
fi

# =============================================================================
# ARCH LINUX / MANJARO
# =============================================================================

if [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
    print_header "Installing GStreamer Packages for Arch Linux"
    echo ""
    
    PACKAGES=(
        # Core GStreamer
        "gstreamer"
        "gst-plugins-base"
        "gst-plugins-good"
        "gst-plugins-bad"
        "gst-plugins-ugly"
        "gst-libav"
        
        # Hardware Acceleration
        "gst-plugin-va"
        "libva"
        "libva-utils"
        "libva-mesa-driver"
        
        # Intel specific (optional but recommended)
        "intel-media-driver"
        
        # Additional codecs
        "x264"
        "x265"
        "libvpx"
        "aom"  # AV1 codec
        "opus"
        "flac"
        "lame"  # MP3 encoder
    )
    
    if [ "$CHECK_ONLY" = true ]; then
        for pkg in "${PACKAGES[@]}"; do
            if is_installed "$pkg"; then
                print_success "$pkg"
            else
                print_warning "$pkg (not installed)"
            fi
        done
    else
        print_info "Installing packages..."
        echo ""
        
        # Update package database
        sudo pacman -Sy
        
        # Install packages
        sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"
        
        print_success "All packages installed successfully!"
    fi

# =============================================================================
# FEDORA / RHEL / CENTOS
# =============================================================================

elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" ]]; then
    print_header "Installing GStreamer Packages for Fedora/RHEL"
    echo ""
    
    PACKAGES=(
        # Core GStreamer
        "gstreamer1"
        "gstreamer1-plugins-base"
        "gstreamer1-plugins-good"
        "gstreamer1-plugins-bad-free"
        "gstreamer1-plugins-ugly-free"
        "gstreamer1-libav"
        
        # Hardware Acceleration
        "libva"
        "libva-utils"
        "mesa-va-drivers"
        "intel-media-driver"
        
        # Additional codecs
        "x264"
        "x265"
        "libvpx"
        "libaom"
        "opus"
        "flac"
    )
    
    # RPM Fusion packages (requires RPM Fusion repo)
    FUSION_PACKAGES=(
        "gstreamer1-plugins-bad-freeworld"
        "gstreamer1-plugins-ugly"
    )
    
    if [ "$CHECK_ONLY" = true ]; then
        for pkg in "${PACKAGES[@]}"; do
            if is_installed "$pkg"; then
                print_success "$pkg"
            else
                print_warning "$pkg (not installed)"
            fi
        done
    else
        print_info "Installing packages..."
        echo ""
        
        # Install main packages
        sudo dnf install -y "${PACKAGES[@]}"
        
        # Check if RPM Fusion is available
        if dnf repolist | grep -q rpmfusion; then
            print_info "Installing RPM Fusion packages..."
            sudo dnf install -y "${FUSION_PACKAGES[@]}" || print_warning "Some RPM Fusion packages not available"
        else
            print_warning "RPM Fusion repository not enabled. Some codecs may be unavailable."
            print_info "Enable with: sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-\$(rpm -E %fedora).noarch.rpm"
        fi
        
        print_success "All packages installed successfully!"
    fi

# =============================================================================
# UBUNTU / DEBIAN
# =============================================================================

elif [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
    print_header "Installing GStreamer Packages for Ubuntu/Debian"
    echo ""
    
    PACKAGES=(
        # Core GStreamer
        "gstreamer1.0-tools"
        "gstreamer1.0-plugins-base"
        "gstreamer1.0-plugins-good"
        "gstreamer1.0-plugins-bad"
        "gstreamer1.0-plugins-ugly"
        "gstreamer1.0-libav"
        
        # Hardware Acceleration
        "gstreamer1.0-vaapi"
        "va-driver-all"
        "vainfo"
        "mesa-va-drivers"
        "intel-media-va-driver"
        
        # Additional codecs
        "libx264-dev"
        "libx265-dev"
        "libvpx-dev"
        "libaom-dev"
        "libopus-dev"
        "flac"
    )
    
    if [ "$CHECK_ONLY" = true ]; then
        for pkg in "${PACKAGES[@]}"; do
            if is_installed "$pkg"; then
                print_success "$pkg"
            else
                print_warning "$pkg (not installed)"
            fi
        done
    else
        print_info "Installing packages..."
        echo ""
        
        # Update package database
        sudo apt update
        
        # Install packages
        sudo apt install -y "${PACKAGES[@]}"
        
        print_success "All packages installed successfully!"
    fi

else
    print_error "Unsupported distribution: $DISTRO"
    print_info "Please install GStreamer packages manually"
    exit 1
fi

echo ""

# =============================================================================
# VERIFICATION
# =============================================================================

if [ "$CHECK_ONLY" = false ]; then
    print_header "Verification"
    echo ""
    
    # Check GStreamer version
    if command -v gst-inspect-1.0 &> /dev/null; then
        GST_VERSION=$(gst-inspect-1.0 --version | head -1 | awk '{print $2}')
        print_success "GStreamer version: $GST_VERSION"
    else
        print_error "GStreamer not found in PATH"
    fi
    
    # Check VA-API
    if command -v vainfo &> /dev/null; then
        print_info "Running VA-API check..."
        if vainfo &> /dev/null; then
            print_success "VA-API hardware acceleration available"
        else
            print_warning "VA-API installed but no compatible hardware detected"
        fi
    else
        print_warning "VA-API tools not installed"
    fi
    
    echo ""
    print_header "Installation Complete!"
    echo ""
    print_info "Next steps:"
    echo "  1. Run: ./scripts/test-gstreamer.sh"
    echo "  2. Launch browser: ./launch-optimized.sh ./build/app/my-browser"
    echo "  3. Test video playback on YouTube or similar sites"
    echo ""
fi
