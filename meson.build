# ==============================================================================
# FILE: meson.build (Root) - CẤU HÌNH BUILD SYSTEM CHÍNH
# ==============================================================================
#
# 📚 MESON BUILD SYSTEM LÀ GÌ?
# ----------------------------
# - Meson là build system hiện đại, nhanh, dễ sử dụng
# - Viết cấu hình bằng ngôn ngữ đơn giản (không phải Makefile phức tạp)
# - Được dùng phổ biến trong các dự án GNOME
#
# 📁 CẤU TRÚC DIRECTORY:
# ----------------------
# my_browser/
# ├── meson.build        ← File này (root configuration)
# ├── build/             ← Thư mục build (tự tạo bởi meson)
# └── app/
#     ├── meson.build    ← File cấu hình cho thư mục app
#     └── *.vala         ← Source files
#
# 🔧 QUY TRÌNH BUILD:
# -------------------
# 1. meson setup build     → Tạo build directory và cấu hình
# 2. ninja -C build        → Biên dịch source code
# 3. ./build/app/my-browser → Chạy ứng dụng
#
# ==============================================================================

# ------------------------------------------------------------------------------
# ĐỊNH NGHĨA DỰ ÁN (Project Definition)
# ------------------------------------------------------------------------------
#
# project(): Khai báo thông tin cơ bản về dự án
#
# Tham số:
#   - 'my_browser': Tên dự án (cũng là prefix cho output files)
#   - 'vala', 'c': Ngôn ngữ sử dụng (Vala được compile thành C)
#   - version: Phiên bản ứng dụng (Semantic Versioning: major.minor.patch)
#   - meson_version: Phiên bản Meson tối thiểu cần có
#
project('my_browser', 'vala', 'c',
  version: '0.1.0',
  meson_version: '>= 0.59.0',
)

# ------------------------------------------------------------------------------
# KHAI BÁO DEPENDENCIES (Thư viện phụ thuộc)
# ------------------------------------------------------------------------------
#
# dependency(): Tìm và link thư viện từ hệ thống
# Meson sử dụng pkg-config để tìm thư viện
#
# Các thư viện cần thiết:
#
# 1. gtk4: GTK 4 - Thư viện UI cơ bản
#    → Cung cấp: Window, Button, Entry, Box, ListBox...
#
# 2. libadwaita-1: Libadwaita - Thư viện UI GNOME
#    → Cung cấp: HeaderBar, TabView, MessageDialog, StyleManager...
#    → Tuân theo GNOME Human Interface Guidelines
#
# 3. webkitgtk-6.0: WebKitGTK 6 - Engine web
#    → Cung cấp: WebView để hiển thị trang web
#    → WebKit là engine của Safari
#
# 4. json-glib-1.0: JSON-GLib - Xử lý JSON
#    → Cung cấp: Json.Parser, Json.Builder để đọc/ghi JSON
#
# 5. libsecret-1: Libsecret - Quản lý mật khẩu
#    → Cung cấp: API để lưu/lấy mật khẩu từ GNOME Keyring
#
# 6. gee-0.8: Libgee - Collection library
#    → Cung cấp: HashSet, ArrayList, HashMap... (advanced collections)
#
deps = [
  dependency('gtk4'),
  dependency('libadwaita-1'),
  dependency('webkitgtk-6.0'),
  dependency('json-glib-1.0'),
  dependency('libsecret-1'),
  dependency('gee-0.8'),
]

# ------------------------------------------------------------------------------
# XỬ LÝ SUBDIRECTORY
# ------------------------------------------------------------------------------
#
# subdir(): Đi vào thư mục con và chạy meson.build ở đó
# Biến 'deps' được inherit xuống app/meson.build
#
subdir('app')

# ==============================================================================
# 📝 HƯỚNG DẪN CÀI ĐẶT DEPENDENCIES
# ==============================================================================
#
# FEDORA/RHEL:
#   sudo dnf install gtk4-devel libadwaita-devel webkitgtk6.0-devel \
#                    json-glib-devel libsecret-devel vala meson ninja-build
#
# UBUNTU/DEBIAN:
#   sudo apt install libgtk-4-dev libadwaita-1-dev libwebkitgtk-6.0-dev \
#                    libjson-glib-dev libsecret-1-dev valac meson ninja-build
#
# ARCH LINUX:
#   sudo pacman -S gtk4 libadwaita webkitgtk-6.0 json-glib libsecret \
#                  vala meson ninja
#
# ==============================================================================
