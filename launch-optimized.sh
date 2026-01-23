#!/bin/bash
# =============================================================================
# LAUNCHER SCRIPT WITH PERFORMANCE OPTIMIZATIONS
# =============================================================================
#
# This script sets WebKit environment variables for better video performance
# before launching the browser

# Force hardware acceleration and threaded rendering
export WEBKIT_FORCE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_COMPOSITING_MODE=0

# Enable threaded compositor (better video performance)
export WEBKIT_USE_THREAD_COMPOSITOR=1

# Enable GPU rasterization
export WEBKIT_ENABLE_GPU_RASTERIZATION=1

# Disable GStreamer GL (can cause issues on some systems)
# Uncomment if you face GL-related crashes:
# export GST_GL_ENABLED=0

# Use GStreamer hardware decoding if available
export GST_VAAPI_ALL_DRIVERS=1

# Thread count for video decoding (adjust based on CPU cores)
export GST_PLUGIN_SCANNER=/usr/lib/gstreamer-1.0/gst-plugin-scanner

# Disable sandbox for network process (can improve performance, less secure)
# Uncomment only if desperate for performance:
# export WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1

# Debug WebKit rendering (useful for diagnosing issues)
# export WEBKIT_DEBUG=all

# Log level
export G_MESSAGES_DEBUG=none

# Run the browser
echo "==================================="
echo "Launching browser with optimizations"
echo "==================================="
echo "Hardware acceleration: ENABLED"
echo "Threaded compositor: ENABLED"
echo "GPU rasterization: ENABLED"
echo "==================================="

exec "$@"
