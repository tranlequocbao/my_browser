#!/bin/bash
# =============================================================================
# COMPREHENSIVE GSTREAMER OPTIMIZATION LAUNCHER
# =============================================================================
#
# This script configures optimal GStreamer settings for video playback in
# WebKitGTK-based browsers, including:
# - Hardware acceleration (VA-API)
# - Codec optimization and ranking
# - Performance tuning
# - Multi-client deployment support
#
# Version: 2.0
# Last updated: 2026-01-23

# =============================================================================
# WEBKIT OPTIMIZATIONS
# =============================================================================

# Force hardware acceleration and threaded rendering
export WEBKIT_FORCE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_COMPOSITING_MODE=0

# Enable threaded compositor (better video performance)
export WEBKIT_USE_THREAD_COMPOSITOR=1

# Enable GPU rasterization
export WEBKIT_ENABLE_GPU_RASTERIZATION=1

# =============================================================================
# GSTREAMER PLUGIN CONFIGURATION
# =============================================================================

# Plugin paths - ensures all plugins are found
export GST_PLUGIN_PATH=/usr/lib/gstreamer-1.0
export GST_PLUGIN_SYSTEM_PATH=/usr/lib/gstreamer-1.0

# Plugin scanner location (for faster startup)
export GST_PLUGIN_SCANNER=/usr/lib/gstreamer-1.0/gst-plugin-scanner

# Use cached plugin registry (faster startup, disable if plugins are updated)
export GST_REGISTRY_UPDATE=no

# =============================================================================
# HARDWARE ACCELERATION (VA-API)
# =============================================================================

# Enable all VA-API drivers for maximum compatibility
export GST_VAAPI_ALL_DRIVERS=1

# Specify VA-API driver (auto-detect by default)
# Uncomment and set based on your hardware:
# Intel GPUs (newer):
# export LIBVA_DRIVER_NAME=iHD
# Intel GPUs (older):
# export LIBVA_DRIVER_NAME=i965
# AMD GPUs:
# export LIBVA_DRIVER_NAME=radeonsi

# VA-API device (default render node)
export GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128

# Disable VA-API if you encounter issues (forces software decoding)
# export GST_VAAPI_DISABLE=1

# =============================================================================
# OPENGL/WAYLAND CONFIGURATION
# =============================================================================

# Set GL window system (wayland or x11)
# Auto-detect based on session
if [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    export GST_GL_WINDOW=wayland
else
    export GST_GL_WINDOW=x11
fi

# Disable GStreamer GL if you encounter rendering issues
# export GST_GL_ENABLED=0

# =============================================================================
# CODEC RANKING AND PREFERENCES
# =============================================================================

# Rank ordering: Hardware decoders > Software decoders
# This is handled automatically by GStreamer, but you can force rankings:
# export GST_PLUGIN_FEATURE_RANK=vaapih264dec:MAX,avdec_h264:SECONDARY

# =============================================================================
# PERFORMANCE TUNING
# =============================================================================

# Adjust based on available CPU cores (detect automatically)
CPU_CORES=$(nproc)
export GST_NUM_THREADS=$CPU_CORES

# Queue size for buffering (larger = smoother playback, more memory)
export GST_QUEUE_DEFAULT_SIZE=100

# Debug level (0=none, 1=error, 2=warning, 3=info, 4+=debug)
# Use 2 for minimal logging, increase for troubleshooting
export GST_DEBUG=2

# Disable colored debug output (cleaner logs)
export GST_DEBUG_NO_COLOR=1

# Uncomment for detailed codec debugging:
# export GST_DEBUG=vaapi:5,codecparsers:4

# =============================================================================
# MEMORY OPTIMIZATION
# =============================================================================

# Enable memory usage optimization
export GST_REGISTRY_FORK=no

# =============================================================================
# WEBKIT SANDBOX (SECURITY vs PERFORMANCE)
# =============================================================================

# By default, sandbox is enabled for security
# Uncomment ONLY if you need maximum performance and understand the risks:
# export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1

# =============================================================================
# LOGGING AND MESSAGES
# =============================================================================

# Suppress unnecessary GLib messages
export G_MESSAGES_DEBUG=none

# =============================================================================
# STARTUP INFORMATION
# =============================================================================

echo "============================================================"
echo "🚀 My Browser - GStreamer Optimized Launcher v2.0"
echo "============================================================"
echo ""
echo "📊 Configuration:"
echo "  • WebKit Hardware Acceleration: ENABLED"
echo "  • WebKit Threaded Compositor: ENABLED"
echo "  • WebKit GPU Rasterization: ENABLED"
echo "  • GStreamer VA-API Support: ENABLED"
echo "  • CPU Cores Detected: $CPU_CORES"
echo "  • OpenGL Window System: ${GST_GL_WINDOW}"
echo ""

# =============================================================================
# HARDWARE ACCELERATION VERIFICATION (Optional)
# =============================================================================

# Check if VA-API is available
if command -v vainfo &> /dev/null; then
    echo "💡 VA-API Status:"
    if vainfo &> /dev/null; then
        echo "  ✅ VA-API hardware acceleration available"
        # Show supported profiles
        VAAPI_PROFILES=$(vainfo 2>&1 | grep -c "VAProfile")
        echo "  • Supported VA-API profiles: $VAAPI_PROFILES"
    else
        echo "  ⚠️  VA-API not available (using software decoding)"
    fi
    echo ""
else
    echo "💡 VA-API: Not installed (software decoding only)"
    echo "   Install with: sudo pacman -S libva-utils"
    echo ""
fi

# =============================================================================
# CODEC AVAILABILITY CHECK (Optional)
# =============================================================================

if [ "$1" = "--check-codecs" ]; then
    echo "🎬 Checking available GStreamer codecs..."
    echo ""
    
    check_codec() {
        local codec=$1
        if gst-inspect-1.0 "$codec" &> /dev/null; then
            echo "  ✅ $codec"
        else
            echo "  ❌ $codec (not found)"
        fi
    }
    
    echo "Video Decoders:"
    check_codec "avdec_h264"
    check_codec "vah264dec"
    check_codec "avdec_h265"
    check_codec "vah265dec"
    check_codec "vp8dec"
    check_codec "vp9dec"
    check_codec "av1dec"
    
    echo ""
    echo "Audio Decoders:"
    check_codec "avdec_aac"
    check_codec "avdec_mp3"
    check_codec "opusdec"
    check_codec "vorbisdec"
    
    echo ""
    echo "============================================================"
    exit 0
fi

echo "============================================================"
echo "🌐 Launching browser..."
echo "============================================================"
echo ""

# =============================================================================
# LAUNCH BROWSER
# =============================================================================

exec "$@"
