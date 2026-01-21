# ==============================================================================
# FILE: app/meson.build - CẤU HÌNH BUILD CHO THƯ MỤC APP
# ==============================================================================
#
# File này định nghĩa:
#   1. Danh sách source files cần compile
#   2. Cách tạo executable
#   3. Data files cần install
#
# ==============================================================================

# ------------------------------------------------------------------------------
# DANH SÁCH SOURCE FILES
# ------------------------------------------------------------------------------
#
# files(): Tạo danh sách các file source
# Thứ tự không quan trọng - Vala compiler tự xử lý dependencies
#
# Các file trong dự án:
#   - main.vala:             Entry point, khởi tạo Application
#   - window.vala:           Giao diện chính, xử lý tabs, web views
#   - history_manager.vala:  Quản lý lịch sử duyệt web (lưu/đọc JSON)
#   - history_dialog.vala:   Dialog hiển thị lịch sử
#   - credential_manager.vala: Quản lý mật khẩu (GNOME Keyring)
#
sources = files(
  'main.vala',
  'window.vala',
  'history_manager.vala',
  'history_dialog.vala',
  'credential_manager.vala',
)

# ------------------------------------------------------------------------------
# TẠO EXECUTABLE VỚI SECURITY HARDENING FLAGS
# ------------------------------------------------------------------------------
#
# executable(): Định nghĩa cách build một executable
#
# Tham số:
#   - 'my-browser': Tên file executable output
#   - sources: Danh sách source files
#   - dependencies: Thư viện cần link (từ root meson.build)
#   - install: true = install vào system khi chạy 'ninja install'
#   - c_args: Compiler flags cho C code
#   - link_args: Linker flags
#
# SECURITY FLAGS:
#   -fstack-protector-strong: Stack canary protection
#   -D_FORTIFY_SOURCE=2: Buffer overflow detection
#   -Wformat -Werror=format-security: Format string protection
#   -Wl,-z,relro: Relocation Read-Only
#   -Wl,-z,now: Full RELRO (immediate binding)
#   -pie: Position Independent Executable
#
# Kết quả: build/app/my-browser (hardened binary)
#
executable('my-browser',
  sources,
  dependencies: deps,
  install: true,
  c_args: [
    '-fstack-protector-strong',  # Stack canaries against buffer overflows
    '-D_FORTIFY_SOURCE=2',       # Runtime buffer overflow checks
    '-Wformat',                   # Check printf/scanf format strings
    '-Werror=format-security',    # Treat format security warnings as errors
  ],
  link_args: [
    '-Wl,-z,relro',              # Mark relocation sections read-only
    '-Wl,-z,now',                # Resolve all symbols at program startup (full RELRO)
    '-pie',                       # Position independent executable for ASLR
  ],
)

# ------------------------------------------------------------------------------
# INSTALL DATA FILES
# ------------------------------------------------------------------------------
#
# install_data(): Copy file vào đường dẫn install
#
# Tham số:
#   - 'autofill.js': File cần install
#   - install_dir: Thư mục đích
#
# get_option('datadir'): Lấy đường dẫn data directory
#   - Mặc định: /usr/local/share
#   - Có thể thay đổi: meson setup build -Dprefix=/usr
#
# Kết quả: /usr/local/share/my-browser/autofill.js
#
# Tại sao cần install autofill.js?
#   - Khi chạy từ build directory: Đọc từ app/autofill.js
#   - Khi install vào system: Đọc từ /usr/local/share/my-browser/autofill.js
#   - window.vala kiểm tra cả 2 đường dẫn
#
install_data('autofill.js', install_dir: get_option('datadir') / 'my-browser')

# ==============================================================================
# 📝 CÁCH SỬ DỤNG
# ==============================================================================
#
# 1. PHÁT TRIỂN (Development):
#    cd /path/to/my_browser
#    meson setup build
#    ninja -C build
#    ./build/app/my-browser
#
# 2. CÀI ĐẶT VÀO HỆ THỐNG:
#    ninja -C build install
#    my-browser
#
# 3. GỠ CÀI ĐẶT:
#    ninja -C build uninstall
#
# 4. XÓA BUILD VÀ BUILD LẠI:
#    rm -rf build
#    meson setup build
#    ninja -C build
#
# ==============================================================================
