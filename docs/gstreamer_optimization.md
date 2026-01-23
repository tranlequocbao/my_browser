# 🎬 GStreamer Optimization Guide for My Browser

This guide provides comprehensive instructions for optimizing GStreamer video playback in the My Browser project, including codec expansion and hardware acceleration setup.

---

## 📑 Table of Contents

1. [Quick Start](#-quick-start)
2. [Package Installation](#-package-installation)
3. [Codec Support Matrix](#-codec-support-matrix)
4. [Hardware Acceleration](#-hardware-acceleration)
5. [Environment Variables](#-environment-variables)
6. [Performance Tuning](#-performance-tuning)
7. [Deployment Guide](#-deployment-guide)
8. [Troubleshooting](#-troubleshooting)

---

## 🚀 Quick Start

### 1. Install Required Packages

```bash
# Run the automated installation script
cd /path/to/my_browser
./scripts/install-gstreamer-codecs.sh
```

### 2. Verify Installation

```bash
# Run diagnostic script
./scripts/test-gstreamer.sh
```

### 3. Launch Browser with Optimizations

```bash
# Use the optimized launcher
./launch-optimized.sh ./build/app/my-browser
```

---

## 📦 Package Installation

### Arch Linux / Manjaro

```bash
sudo pacman -S gstreamer gst-plugins-base gst-plugins-good \
               gst-plugins-bad gst-plugins-ugly gst-libav \
               gst-plugin-va libva libva-utils libva-mesa-driver \
               intel-media-driver x264 x265 libvpx aom opus flac lame
```

### Fedora / RHEL / CentOS

```bash
sudo dnf install gstreamer1 gstreamer1-plugins-base \
                 gstreamer1-plugins-good gstreamer1-plugins-bad-free \
                 gstreamer1-plugins-ugly-free gstreamer1-libav \
                 libva libva-utils mesa-va-drivers intel-media-driver \
                 x264 x265 libvpx libaom opus flac

# Optional: Install RPM Fusion for additional codecs
sudo dnf install gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly
```

### Ubuntu / Debian

```bash
sudo apt install gstreamer1.0-tools gstreamer1.0-plugins-base \
                 gstreamer1.0-plugins-good gstreamer1.0-plugins-bad \
                 gstreamer1.0-plugins-ugly gstreamer1.0-libav \
                 gstreamer1.0-vaapi va-driver-all vainfo \
                 mesa-va-drivers intel-media-va-driver \
                 libx264-dev libx265-dev libvpx-dev libaom-dev \
                 libopus-dev flac
```

---

## 🎬 Codec Support Matrix

| Codec | Format | Hardware Acceleration | Software Fallback | Common Use |
|-------|--------|----------------------|-------------------|-----------|
| **H.264 (AVC)** | MP4, MKV, TS | ✅ VA-API (Intel/AMD) | ✅ libav | YouTube, most videos |
| **H.265 (HEVC)** | MP4, MKV | ✅ VA-API (Intel/AMD) | ✅ libav | 4K videos, modern content |
| **VP8** | WebM | ✅ VA-API | ✅ Native | Older WebM videos |
| **VP9** | WebM | ✅ VA-API | ✅ Native | YouTube, high-quality |
| **AV1** | MP4, WebM | ✅ VA-API (newer GPUs) | ✅ Native | Next-gen codec |
| **AAC** | MP4, M4A | N/A | ✅ libav | Most audio streams |
| **MP3** | MP3, MP4 | N/A | ✅ libav | Legacy audio |
| **Opus** | WebM, Ogg | N/A | ✅ Native | High-quality audio |
| **Vorbis** | Ogg, WebM | N/A | ✅ Native | Open source audio |
| **FLAC** | FLAC, MKV | N/A | ✅ Native | Lossless audio |

### Container Formats

- **MP4/M4V**: ✅ Fully supported
- **WebM**: ✅ Fully supported
- **MKV (Matroska)**: ✅ Fully supported
- **AVI**: ✅ Supported (limited)
- **Ogg**: ✅ Supported

---

## 🔧 Hardware Acceleration

### VA-API (Intel/AMD GPUs)

#### 1. Verify Hardware Support

```bash
# Intel/AMD GPUs should have a render device
ls -l /dev/dri/
# Should show renderD128 or similar

# Check VA-API capabilities
vainfo
```

**Expected output:**
```
libva info: VA-API version 1.x.x
libva info: User environment variable requested driver 'iHD'
VAProfileH264Main
VAProfileH264High
VAProfileHEVCMain
VAProfileVP9Profile0
...
```

#### 2. Configuration

The `launch-optimized.sh` script automatically configures VA-API. Key settings:

```bash
export GST_VAAPI_ALL_DRIVERS=1              # Enable all VA-API drivers
export GST_VAAPI_DRM_DEVICE=/dev/dri/renderD128  # Default render device
```

#### 3. Driver Selection

**Intel GPUs:**
- **Newer (9th gen+)**: `export LIBVA_DRIVER_NAME=iHD` (intel-media-driver)
- **Older (7th-8th gen)**: `export LIBVA_DRIVER_NAME=i965` (libva-intel-driver)

**AMD GPUs:**
```bash
export LIBVA_DRIVER_NAME=radeonsi
```

The launcher auto-detects in most cases. Override if needed.

#### 4. Verification

```bash
# Check if hardware decoder is being used
./scripts/test-gstreamer.sh --full

# Look for entries like:
# ✅ H.264 (VA-API) (vah264dec)
# ✅ H.265/HEVC (VA-API) (vah265dec)
```

---

### NVIDIA GPUs (VDPAU)

> [!NOTE]
> WebKitGTK primarily uses VA-API. For NVIDIA GPUs, consider using the `vdpau-va-driver` wrapper.

```bash
# Arch Linux
sudo pacman -S libvdpau-va-gl

# Fedora
sudo dnf install libvdpau-va-gl

# Ubuntu/Debian
sudo apt install vdpau-va-driver
```

Then set:
```bash
export VDPAU_DRIVER=nvidia
export LIBVA_DRIVER_NAME=vdpau
```

---

## ⚙️ Environment Variables

### Core GStreamer Settings

| Variable | Value | Description |
|----------|-------|-------------|
| `GST_PLUGIN_PATH` | `/usr/lib/gstreamer-1.0` | Plugin location |
| `GST_PLUGIN_SCANNER` | `/usr/lib/gstreamer-1.0/gst-plugin-scanner` | Faster startup |
| `GST_REGISTRY_UPDATE` | `no` | Use cached registry |
| `GST_DEBUG` | `2` | Log level (0-5) |

### Hardware Acceleration

| Variable | Value | Description |
|----------|-------|-------------|
| `GST_VAAPI_ALL_DRIVERS` | `1` | Enable all VA-API drivers |
| `GST_VAAPI_DRM_DEVICE` | `/dev/dri/renderD128` | Render device |
| `LIBVA_DRIVER_NAME` | `iHD`/`i965`/`radeonsi` | VA-API driver |

### Performance Tuning

| Variable | Value | Description |
|----------|-------|-------------|
| `GST_NUM_THREADS` | `$(nproc)` | Thread count (auto-detect) |
| `GST_QUEUE_DEFAULT_SIZE` | `100` | Buffer queue size |
| `GST_REGISTRY_FORK` | `no` | Memory optimization |

### Display System

| Variable | Value | Description |
|----------|-------|-------------|
| `GST_GL_WINDOW` | `wayland`/`x11` | GL window system (auto) |

---

## 🚀 Performance Tuning

### CPU vs GPU Decoding

**Hardware (GPU) Decoding - Recommended:**
- ✅ Lower CPU usage (5-15% for 1080p)
- ✅ Better battery life on laptops
- ✅ Can handle 4K easily
- ⚠️ Requires compatible GPU

**Software (CPU) Decoding - Fallback:**
- CPU usage: 30-60% for 1080p
- Still functional for HD content
- Used when GPU acceleration unavailable

### Memory Management

For systems with limited RAM, adjust queue sizes:

```bash
# In launch-optimized.sh
export GST_QUEUE_DEFAULT_SIZE=50  # Reduce from 100
```

### Thread Configuration

The launcher auto-detects CPU cores. Manual override:

```bash
# Force specific thread count
export GST_NUM_THREADS=4
```

### Debugging Performance Issues

Enable detailed logging:

```bash
# Add to launch-optimized.sh temporarily
export GST_DEBUG=vaapi:5,codecparsers:4
export GST_DEBUG_NO_COLOR=0

# Then check logs for:
# - Which decoder is being selected
# - If VA-API initialization succeeds
# - Any error messages
```

---

## 📋 Deployment Guide

### Setting Up on New Client Machines

#### Step 1: Clone/Copy Project

```bash
git clone <repository> my_browser
cd my_browser
```

#### Step 2: Install Dependencies

```bash
# System packages (from main README)
sudo pacman -S gtk4-devel libadwaita-devel webkitgtk6.0-devel \
               json-glib-devel libsecret-devel vala meson ninja-build

# GStreamer codecs
./scripts/install-gstreamer-codecs.sh
```

#### Step 3: Build Browser

```bash
meson setup build
ninja -C build
```

#### Step 4: Verify Setup

```bash
# Run diagnostic
./scripts/test-gstreamer.sh

# Expected output should show:
# ✅ VA-API hardware acceleration available
# ✅ All major codecs present
```

#### Step 5: Test Playback

```bash
# Launch browser
./launch-optimized.sh ./build/app/my-browser

# Test on:
# - https://www.youtube.com/watch?v=aqz-KE-bpKQ (H.264)
# - Any YouTube video (VP9)
```

### Quick Setup Script

Create `quick-setup.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 My Browser - Quick Setup"
echo ""

# Install GStreamer
./scripts/install-gstreamer-codecs.sh

# Build
meson setup build --buildtype=release
ninja -C build

# Test
./scripts/test-gstreamer.sh

echo ""
echo "✅ Setup complete!"
echo "Launch with: ./launch-optimized.sh ./build/app/my-browser"
```

---

## 🔍 Troubleshooting

### Common Issues

#### No Hardware Acceleration

**Symptoms:**
- High CPU usage during video playback (>40%)
- `vainfo` command fails

**Solutions:**

1. **Check GPU support:**
   ```bash
   lspci | grep -i vga
   ```

2. **Install correct drivers:**
   ```bash
   # Intel
   sudo pacman -S intel-media-driver libva-intel-driver
   
   # AMD
   sudo pacman -S libva-mesa-driver
   ```

3. **Verify permissions:**
   ```bash
   # User should be in 'video' group
   groups
   # If missing: sudo usermod -aG video $USER
   ```

#### Video Stuttering/Dropped Frames

**Solutions:**

1. **Increase buffer size:**
   ```bash
   # In launch-optimized.sh
   export GST_QUEUE_DEFAULT_SIZE=200
   ```

2. **Check system load:**
   ```bash
   # Ensure other processes aren't consuming resources
   htop
   ```

3. **Disable GL if causing issues:**
   ```bash
   export GST_GL_ENABLED=0
   ```

#### Codec Not Found

**Symptoms:**
- "Could not play video" errors
- Specific format won't load

**Solutions:**

1. **Check available codecs:**
   ```bash
   ./scripts/test-gstreamer.sh --full
   ```

2. **Install missing packages:**
   ```bash
   # For H.265/HEVC
   sudo pacman -S gst-plugins-bad
   
   # For proprietary codecs
   sudo pacman -S gst-plugins-ugly
   ```

#### Black Screen on Wayland

**Solutions:**

1. **Force Wayland backend:**
   ```bash
   export GST_GL_WINDOW=wayland
   ```

2. **Or try X11 backend:**
   ```bash
   export GST_GL_WINDOW=x11
   ```

#### Permission Denied for /dev/dri

**Solution:**
```bash
# Add user to video/render group
sudo usermod -aG video,render $USER
# Logout and login again
```

---

## 📊 Performance Benchmarks

### Expected CPU Usage (1080p YouTube)

| Configuration | CPU Usage | Status |
|---------------|-----------|--------|
| **Hardware Acceleration (VA-API)** | 5-15% | ✅ Optimal |
| **Software Decoding (H.264)** | 25-40% | ⚠️ Acceptable |
| **Software Decoding (VP9/AV1)** | 40-60% | ⚠️ High |

### 4K Video (2160p)

| Configuration | CPU Usage | Playback |
|---------------|-----------|----------|
| **Hardware Acceleration** | 10-25% | ✅ Smooth |
| **Software Decoding** | 70-100% | ❌ Laggy |

> [!TIP]
> If CPU usage is high, check that hardware acceleration is working with `./scripts/test-gstreamer.sh`

---

## 🔗 Additional Resources

- [GStreamer Documentation](https://gstreamer.freedesktop.org/documentation/)
- [VA-API Documentation](https://github.com/intel/libva)
- [WebKitGTK Documentation](https://webkitgtk.org/)
- [Arch Wiki: Hardware Video Acceleration](https://wiki.archlinux.org/title/Hardware_video_acceleration)

---

## 📝 Notes

- **Codec Licensing**: Some codecs (H.264, H.265) may require separate licensing for commercial use
- **Plugin Updates**: After updating GStreamer packages, set `GST_REGISTRY_UPDATE=yes` once to refresh cache
- **Browser-Specific**: These optimizations apply to WebKitGTK-based applications
- **Hardware-Dependent**: Actual performance varies by CPU/GPU capabilities

---

**Last Updated:** 2026-01-23  
**GStreamer Version:** 1.26.x  
**WebKitGTK Version:** 6.0
