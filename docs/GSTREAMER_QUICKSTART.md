# 🎬 Tối Ưu Video & GStreamer - Quick Reference

> **Phần mở rộng cho README.md** - Hướng dẫn nhanh về tối ưu GStreamer

---

## Quick Start Guide

### 1. Cài Đặt Codecs

```bash
# Tự động cài đặt tất cả packages (Arch Linux)
./scripts/install-gstreamer-codecs.sh
```

### 2. Kiểm Tra Hệ Thống

```bash
# Diagnostic script
./scripts/test-gstreamer.sh
```

### 3. Chạy Browser

```bash
# Với optimizations
./launch-optimized.sh ./build/app/my-browser

# Kiểm tra codecs
./launch-optimized.sh --check-codecs
```

---

## Codec Support

| Codec | Hardware | Software | Use Case |
|-------|----------|----------|----------|
| **H.264** | ✅ | ✅ | YouTube, hầu hết videos |
| **H.265** | ✅ | ✅ | 4K content |
| **VP9** | ✅ | ✅ | YouTube HD |
| **AV1** | ⚡ | ✅ | Next-gen |

---

## Performance

| Config | 1080p CPU | 4K CPU |
|--------|-----------|--------|
| **Hardware** | 5-15% | 10-25% |
| **Software** | 25-40% | 70-100% |

---

## Troubleshooting

**Video không phát:**
```bash
./scripts/test-gstreamer.sh
```

**CPU cao:**
```bash
vainfo  # Kiểm tra VA-API
```

---

## Tài Liệu Đầy Đủ

📖 **Xem chi tiết tại:** [`docs/gstreamer_optimization.md`](gstreamer_optimization.md)

Bao gồm:
- Hướng dẫn cài đặt cho tất cả Linux distros
- Hardware acceleration setup
- Performance tuning chi tiết
- Deployment guide
- Troubleshooting toàn diện
