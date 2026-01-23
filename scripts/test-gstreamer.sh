#!/bin/bash
# =============================================================================
# GSTREAMER DIAGNOSTIC AND TESTING SCRIPT
# =============================================================================
#
# This script performs comprehensive diagnostics of the GStreamer setup,
# including codec availability, hardware acceleration, and performance checks.
#
# Usage: ./test-gstreamer.sh [--full | --quick | --report]
#
# Modes:
#   --quick: Fast check of essential components (default)
#   --full:  Comprehensive codec and plugin enumeration
#   --report: Generate detailed report file
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Mode selection
MODE="${1:---quick}"
REPORT_FILE="gstreamer_report_$(date +%Y%m%d_%H%M%S).txt"

# =============================================================================
# FUNCTIONS
# =============================================================================

print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_section() {
    echo -e "${CYAN}▶  $1${NC}"
}

print_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

print_info() {
    echo -e "  💡 $1"
}

check_codec() {
    local codec=$1
    local description=$2
    
    if gst-inspect-1.0 "$codec" &> /dev/null; then
        print_success "$description ($codec)"
        return 0
    else
        print_error "$description ($codec) - NOT FOUND"
        return 1
    fi
}

# =============================================================================
# SYSTEM INFORMATION
# =============================================================================

print_header "GStreamer System Diagnostics"
echo ""
echo "Mode: $MODE"
echo "Date: $(date)"
echo ""

print_section "System Information"
echo "  OS: $(uname -s)"
echo "  Kernel: $(uname -r)"
echo "  CPU: $(nproc) cores"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  Distribution: $NAME $VERSION"
fi

echo "  Display Server: ${XDG_SESSION_TYPE:-unknown}"
echo ""

# =============================================================================
# GSTREAMER VERSION
# =============================================================================

print_section "GStreamer Version"

if command -v gst-inspect-1.0 &> /dev/null; then
    GST_VERSION=$(gst-inspect-1.0 --version 2>&1 | grep "GStreamer" | head -1)
    print_success "$GST_VERSION"
else
    print_error "GStreamer not found!"
    exit 1
fi

echo ""

# =============================================================================
# PLUGIN PACKAGES CHECK
# =============================================================================

print_section "GStreamer Plugin Packages"

PLUGIN_LIBS=(
    "libgstcoreelements.so"
    "libgstplayback.so"
    "libgstlibav.so"
    "libgstvideoparsersbad.so"
)

for lib in "${PLUGIN_LIBS[@]}"; do
    if [ -f "/usr/lib/gstreamer-1.0/$lib" ]; then
        print_success "$lib"
    else
        print_warning "$lib not found"
    fi
done

echo ""

# =============================================================================
# HARDWARE ACCELERATION
# =============================================================================

print_section "Hardware Acceleration (VA-API)"

if command -v vainfo &> /dev/null; then
    print_success "vainfo tool installed"
    
    if vainfo &> /dev/null 2>&1; then
        print_success "VA-API hardware acceleration functional"
        
        # Count supported profiles
        PROFILE_COUNT=$(vainfo 2>&1 | grep -c "VAProfile" || true)
        print_info "Supported VA-API profiles: $PROFILE_COUNT"
        
        if [ "$MODE" = "--full" ]; then
            echo ""
            print_info "VA-API Profiles:"
            vainfo 2>&1 | grep "VAProfile" | sed 's/^/    /'
        fi
    else
        print_warning "VA-API installed but no compatible hardware"
        print_info "Software decoding will be used"
    fi
else
    print_warning "VA-API not installed"
    print_info "Install with: sudo pacman -S libva-utils (Arch)"
fi

echo ""

# =============================================================================
# VIDEO CODECS
# =============================================================================

print_section "Video Codec Support"

echo ""
echo "  Hardware Decoders (VA-API):"
check_codec "vah264dec" "H.264 (VA-API)" || true
check_codec "vah265dec" "H.265/HEVC (VA-API)" || true
check_codec "vavp8dec" "VP8 (VA-API)" || true
check_codec "vavp9dec" "VP9 (VA-API)" || true
check_codec "vaav1dec" "AV1 (VA-API)" || true

echo ""
echo "  Software Decoders (libav/FFmpeg):"
check_codec "avdec_h264" "H.264 (Software)" || true
check_codec "avdec_h265" "H.265/HEVC (Software)" || true
check_codec "vp8dec" "VP8 (Software)" || true
check_codec "vp9dec" "VP9 (Software)" || true
check_codec "av1dec" "AV1 (Software)" || true

echo ""

# =============================================================================
# AUDIO CODECS
# =============================================================================

print_section "Audio Codec Support"

check_codec "avdec_aac" "AAC" || true
check_codec "avdec_mp3" "MP3" || true
check_codec "opusdec" "Opus" || true
check_codec "vorbisdec" "Vorbis" || true
check_codec "flacdec" "FLAC" || true
check_codec "avdec_ac3" "AC3/Dolby Digital" || true

echo ""

# =============================================================================
# PARSERS AND DEMUXERS
# =============================================================================

if [ "$MODE" = "--full" ]; then
    print_section "Parsers and Demuxers"
    
    echo ""
    echo "  Video Parsers:"
    check_codec "h264parse" "H.264 Parser" || true
    check_codec "h265parse" "H.265 Parser" || true
    check_codec "vp8parse" "VP8 Parser" || true
    check_codec "vp9parse" "VP9 Parser" || true
    
    echo ""
    echo "  Container Demuxers:"
    check_codec "matroskademux" "Matroska/MKV" || true
    check_codec "qtdemux" "MP4/QuickTime" || true
    check_codec "avidemux" "AVI" || true
    check_codec "oggdemux" "Ogg" || true
    
    echo ""
fi

# =============================================================================
# PLUGIN STATISTICS
# =============================================================================

if [ "$MODE" = "--full" ]; then
    print_section "Plugin Statistics"
    
    TOTAL_PLUGINS=$(gst-inspect-1.0 2>/dev/null | grep -c "plugin:" || true)
    TOTAL_ELEMENTS=$(gst-inspect-1.0 2>/dev/null | wc -l || true)
    
    print_info "Total plugins: $TOTAL_PLUGINS"
    print_info "Total elements: $TOTAL_ELEMENTS"
    
    echo ""
fi

# =============================================================================
# ENVIRONMENT VARIABLES CHECK
# =============================================================================

print_section "GStreamer Environment Variables"

ENV_VARS=(
    "GST_PLUGIN_PATH"
    "GST_PLUGIN_SCANNER"
    "GST_VAAPI_ALL_DRIVERS"
    "GST_DEBUG"
    "LIBVA_DRIVER_NAME"
)

HAS_ENV=false
for var in "${ENV_VARS[@]}"; do
    if [ -n "${!var}" ]; then
        print_info "$var=${!var}"
        HAS_ENV=true
    fi
done

if [ "$HAS_ENV" = false ]; then
    print_info "No GStreamer environment variables currently set"
    print_info "Launch browser with: ./launch-optimized.sh ./build/app/my-browser"
fi

echo ""

# =============================================================================
# RECOMMENDATIONS
# =============================================================================

print_section "Recommendations"

MISSING_COUNT=0

# Check for essential plugins
if ! gst-inspect-1.0 libgstlibav.so &> /dev/null; then
    print_warning "Install gst-libav for better codec support"
    ((MISSING_COUNT++))
fi

# Check for VA-API hardware decoder
if ! gst-inspect-1.0 vah264dec &> /dev/null && ! gst-inspect-1.0 vaapih264dec &> /dev/null; then
    print_warning "Install gst-plugin-va or gstreamer-vaapi for hardware acceleration"
    print_info "Command: sudo pacman -S gst-plugin-va libva-mesa-driver"
    ((MISSING_COUNT++))
fi

# Check for ugly plugins
if ! gst-inspect-1.0 x264enc &> /dev/null; then
    print_warning "Install gst-plugins-ugly for additional codecs"
    print_info "Command: sudo pacman -S gst-plugins-ugly"
    ((MISSING_COUNT++))
fi

if [ $MISSING_COUNT -eq 0 ]; then
    print_success "All essential components are installed!"
else
    print_info "Run: ./scripts/install-gstreamer-codecs.sh"
fi

echo ""

# =============================================================================
# CODEC COMPATIBILITY SUMMARY
# =============================================================================

print_section "Codec Compatibility Summary"

# Count available decoders
H264_HW=0; H264_SW=0
H265_HW=0; H265_SW=0
VP9_HW=0; VP9_SW=0
AV1_HW=0; AV1_SW=0

gst-inspect-1.0 vah264dec &> /dev/null && H264_HW=1 || true
gst-inspect-1.0 avdec_h264 &> /dev/null && H264_SW=1 || true
gst-inspect-1.0 vah265dec &> /dev/null && H265_HW=1 || true
gst-inspect-1.0 avdec_h265 &> /dev/null && H265_SW=1 || true
gst-inspect-1.0 vavp9dec &> /dev/null && VP9_HW=1 || true
gst-inspect-1.0 vp9dec &> /dev/null && VP9_SW=1 || true
gst-inspect-1.0 vaav1dec &> /dev/null && AV1_HW=1 || true
gst-inspect-1.0 av1dec &> /dev/null && AV1_SW=1 || true

echo ""
echo "  Codec          Hardware    Software    Status"
echo "  ────────────   ─────────   ─────────   ──────"

print_codec_status() {
    local name=$1
    local hw=$2
    local sw=$3
    
    printf "  %-14s " "$name"
    
    if [ $hw -eq 1 ]; then
        printf "${GREEN}%-11s${NC} " "✅ YES"
    else
        printf "%-11s " "❌ NO"
    fi
    
    if [ $sw -eq 1 ]; then
        printf "${GREEN}%-11s${NC} " "✅ YES"
    else
        printf "%-11s " "❌ NO"
    fi
    
    if [ $hw -eq 1 ]; then
        echo -e "${GREEN}✅ OPTIMAL${NC}"
    elif [ $sw -eq 1 ]; then
        echo -e "${YELLOW}⚠️  SOFTWARE ONLY${NC}"
    else
        echo -e "${RED}❌ MISSING${NC}"
    fi
}

print_codec_status "H.264" $H264_HW $H264_SW
print_codec_status "H.265/HEVC" $H265_HW $H265_SW
print_codec_status "VP9" $VP9_HW $VP9_SW
print_codec_status "AV1" $AV1_HW $AV1_SW

echo ""

# =============================================================================
# PERFORMANCE TEST
# =============================================================================

if [ "$MODE" = "--full" ]; then
    print_section "Performance Test"
    
    print_info "Testing plugin load time..."
    
    START_TIME=$(date +%s%N)
    gst-inspect-1.0 &> /dev/null || true
    END_TIME=$(date +%s%N)
    
    LOAD_TIME=$(( (END_TIME - START_TIME) / 1000000 ))
    
    if [ $LOAD_TIME -lt 500 ]; then
        print_success "Plugin load time: ${LOAD_TIME}ms (excellent)"
    elif [ $LOAD_TIME -lt 1000 ]; then
        print_success "Plugin load time: ${LOAD_TIME}ms (good)"
    else
        print_warning "Plugin load time: ${LOAD_TIME}ms (consider clearing cache)"
    fi
    
    echo ""
fi

# =============================================================================
# REPORT GENERATION
# =============================================================================

if [ "$MODE" = "--report" ]; then
    print_section "Generating Report"
    
    {
        echo "GStreamer Diagnostic Report"
        echo "Generated: $(date)"
        echo ""
        echo "=== System Information ==="
        uname -a
        echo ""
        
        if [ -f /etc/os-release ]; then
            cat /etc/os-release
            echo ""
        fi
        
        echo "=== GStreamer Version ==="
        gst-inspect-1.0 --version
        echo ""
        
        echo "=== VA-API Information ==="
        vainfo 2>&1 || echo "VA-API not available"
        echo ""
        
        echo "=== Available Decoders ==="
        gst-inspect-1.0 | grep -E "(decoder|demux|parser)" || true
        echo ""
        
        echo "=== Plugin List ==="
        gst-inspect-1.0 2>/dev/null || true
        
    } > "$REPORT_FILE"
    
    print_success "Report saved to: $REPORT_FILE"
    echo ""
fi

# =============================================================================
# FINISH
# =============================================================================

print_header "Diagnostic Complete"
echo ""
print_info "To test video playback:"
echo "  1. Launch browser: ./launch-optimized.sh ./build/app/my-browser"
echo "  2. Visit: https://www.youtube.com/watch?v=aqz-KE-bpKQ"
echo "  3. Check CPU usage during playback (should be < 30% with HW acceleration)"
echo ""
print_info "For more details, run: $0 --full"
echo ""
