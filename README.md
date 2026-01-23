# 🌐 My Browser - Trình Duyệt Web Tùy Chỉnh

Chào mừng bạn đến với dự án **My Browser**! Đây là một trình duyệt web được xây dựng bằng **Vala** và **GTK4/Libadwaita**, sử dụng **WebKitGTK** làm engine hiển thị. Tài liệu này sẽ hướng dẫn bạn hiểu rõ cấu trúc project, cách nó hoạt động, và cách bắt đầu phát triển.

---

## 📚 Mục Lục

1. [Tổng Quan Dự Án](#-1-tổng-quan-dự-án)
2. [Cấu Trúc Dự Án](#-2-cấu-trúc-dự-án)
3. [Luồng Hoạt Động Tổng Quát](#-3-luồng-hoạt-động-tổng-quát)
4. [Bắt Đầu Từ Đâu?](#-4-bắt-đầu-từ-đâu-getting-started)
5. [Hướng Dẫn Chi Tiết Từng File](#-5-hướng-dẫn-chi-tiết-từng-file)
6. [Hệ Thống Password Manager](#-6-hệ-thống-password-manager)
7. [Hệ Thống Session & Cookie](#-7-hệ-thống-session--cookie)
8. [Hệ Thống Lịch Sử Duyệt Web](#-8-hệ-thống-lịch-sử-duyệt-web)
9. [**🎬 Tối Ưu Video & GStreamer**](#-9-tối-ưu-video--gstreamer) ⭐ **MỚI**
10. [Biên Dịch và Chạy Ứng Dụng](#-10-biên-dịch-và-chạy-ứng-dụng)
11. [Tài Liệu Tham Khảo](#-11-tài-liệu-tham-khảo)

---

## 🎯 1. Tổng Quan Dự Án

### 1.1. Dự Án Này Là Gì?

**My Browser** là một trình duyệt web đơn giản nhưng đầy đủ tính năng, được viết bằng ngôn ngữ **Vala** - một ngôn ngữ lập trình hiện đại tương tự C# nhưng biên dịch thành C native.

### 1.2. Tính Năng Chính

| Tính Năng | Mô Tả |
|-----------|-------|
| 🌐 **Duyệt Web** | Hiển thị trang web với WebKitGTK engine (giống Safari) |
| 📑 **Quản Lý Tab** | Mở nhiều tab, chuyển đổi giữa các tab |
| 🔐 **Password Manager** | Tự động lưu và điền mật khẩu đăng nhập |
| 🕐 **Lịch Sử Duyệt Web** | Ghi lại và xem lại các trang đã truy cập |
| 🍪 **Cookie Persistence** | Lưu trữ session và cookie qua các lần restart |
| 🎨 **Giao Diện GNOME** | Thiết kế theo GNOME Human Interface Guidelines |

### 1.4. Bảo Mật (Security Features)

> **📅 Cập nhật:** 2026-01-21 - Major security enhancements implemented

**My Browser** đã được tăng cường bảo mật với các tính năng sau:

| Tính Năng Bảo Mật | Mô Tả | File Triển Khai | Mức Độ |
|-------------------|-------|-----------------|---------|
| 🛡️ **Compiler Hardening** | Stack protection, RELRO, PIE, FORTIFY_SOURCE | `app/meson.build` | 🔴 HIGH |
| 🔒 **XSS Protection** | One-time token verification cho autofill | `autofill.js`, `window.vala` | 🔴 HIGH |
| 🔐 **Secure Password Storage** | GNOME Keyring với mã hóa hệ thống | `credential_manager.vala` | 🔴 HIGH |
| 🚫 **Third-Party Cookie Blocking** | Chặn tracking cookies | `window.vala` | 🟡 MEDIUM |
| ✅ **IPC Message Validation** | Strict validation với whitelist, size limits | `window.vala` | 🟡 MEDIUM |
| 🔗 **URL Scheme Filtering** | Block javascript:, data:, vbscript: | `window.vala` | 🟡 MEDIUM |
| 🔐 **TLS Error Handling** | User warnings cho invalid certificates | `window.vala` | 🟡 MEDIUM |
| 📁 **File Access Restrictions** | Ngăn cross-origin file access | `window.vala` | 🟡 MEDIUM |
| 🐛 **Conditional DevTools** | Developer extras chỉ trong DEBUG builds | `window.vala` | 🟡 MEDIUM |
| 🛡️ **JSON Encoding** | Safe credential passing without injection | `window.vala` | 🔴 HIGH |

**Security Score:** 78/100 (+16 từ version trước)

**Báo cáo bảo mật:**
- 📄 [`Security_Fixes_Report.md`](Security_Fixes_Report.md) - Chi tiết các lỗi XSS đã fix
- 📄 [`enhance_security_version_20260121.md`](enhance_security_version_20260121.md) - Tổng hợp cải tiến bảo mật
- 📄 [`Chrome_Security_Audit.md`](Chrome_Security_Audit.md) - Đánh giá theo chuẩn Chrome


### 1.3. Công Nghệ Sử Dụng

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          TECHNOLOGY STACK                                 │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                          │y
│  ┌─────────────┐                                                         │
│  │    Vala     │  ← Ngôn ngữ lập trình (biên dịch thành C)              │
│  └──────┬──────┘                                                         │
│         │                                                                │
│  ┌──────┴──────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │    GTK4     │  │ Libadwaita  │  │ WebKitGTK   │  │  Libsecret  │     │
│  │  (UI Core)  │  │(GNOME Theme)│  │(Web Engine) │  │ (Passwords) │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │                │            │
│  ┌──────┴────────────────┴────────────────┴────────────────┴──────┐     │
│  │                           GLib                                  │     │
│  │              (Thư viện nền tảng của GNOME)                      │     │
│  └────────────────────────────────────────────────────────────────┘     │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 📁 2. Cấu Trúc Dự Án

```
my_browser/
│
├── 📄 meson.build              # [1] Cấu hình build chính - ĐIỂM BẮT ĐẦU BUILD
├── 📄 README.md                # [2] Tài liệu hướng dẫn (file này)
│
├── � Security_Fixes_Report.md # [3] Báo cáo chi tiết các lỗi XSS đã fix
├── 🔐 enhance_security_version_20260121.md  # [4] Tổng hợp cải tiến bảo mật
├── 🔐 Chrome_Security_Audit.md # [5] Đánh giá bảo mật theo chuẩn Chrome
├── 🔐 SecurityAssessment.md    # [6] Đánh giá bảo mật ban đầu
│
├── �🗂️ build/                   # [7] Thư mục build (tự động tạo bởi Meson)
│   └── app/
│       └── my-browser          # [8] File thực thi cuối cùng (hardened binary)
│
└── 🗂️ app/                     # [9] THƯ MỤC SOURCE CODE CHÍNH
    │
    ├── 📄 meson.build          # [10] Cấu hình build + SECURITY FLAGS
    │                           #      → Stack protection, RELRO, PIE
    │
    ├── 📄 main.vala            # [11] ENTRY POINT - Điểm vào chương trình
    │                           #      → Khởi tạo Application
    │                           #      → Thiết lập vòng đời ứng dụng
    │
    ├── 📄 window.vala          # [12] CỬA SỔ CHÍNH - Trái tim của ứng dụng
    │                           #      → Giao diện người dùng
    │                           #      → Quản lý tabs và WebViews
    │                           #      → Xử lý navigation
    │                           #      → 🔒 IPC validation, TLS handling
    │                           #      → 🔒 URL scheme filtering
    │
    ├── 📄 credential_manager.vala # [13] QUẢN LÝ MẬT KHẨU
    │                              #      → Lưu/lấy mật khẩu từ GNOME Keyring
    │                              #      → 🔒 Encrypted storage
    │                              #      → Singleton pattern
    │
    ├── 📄 history_manager.vala # [14] QUẢN LÝ LỊCH SỬ
    │                           #      → Lưu/đọc lịch sử từ JSON file
    │                           #      → Singleton pattern
    │
    ├── 📄 history_dialog.vala  # [15] DIALOG LỊCH SỬ
    │                           #      → Hiển thị danh sách lịch sử
    │                           #      → Cho phép mở lại trang đã truy cập
    │
    └── 📄 autofill.js          # [16] JAVASCRIPT INJECTION
                                #      → Được inject vào mọi trang web
                                #      → Phát hiện form đăng nhập
                                #      → 🔒 Token-based autofill
                                #      → 🔒 No sensitive logging
                                #      → Phát hiện form đăng nhập
                                #      → Giao tiếp với Vala backend
```

### 2.1. Thứ Tự Đọc Code Đề Xuất

Nếu bạn mới bắt đầu, hãy đọc code theo thứ tự sau:

```
1. meson.build (root)     → Hiểu build system và dependencies
      ↓
2. app/meson.build        → Hiểu danh sách source files
      ↓
3. main.vala              → Hiểu entry point và vòng đời app
      ↓
4. window.vala            → Hiểu UI structure và logic chính
      ↓
5. history_manager.vala   → Hiểu persistent storage với JSON
      ↓
6. history_dialog.vala    → Hiểu GTK widgets và signals
      ↓
7. credential_manager.vala → Hiểu tích hợp với GNOME Keyring
      ↓
8. autofill.js            → Hiểu JavaScript injection
```

---

## 🔄 3. Luồng Hoạt Động Tổng Quát

### 3.1. Vòng Đời Ứng Dụng (Application Lifecycle)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          VÒNG ĐỜI ỨNG DỤNG                              │
└─────────────────────────────────────────────────────────────────────────┘

    Terminal: ./build/app/my-browser
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  main.vala: main()                    │
    │  → Tạo BrowserApp instance            │
    │  → Gọi app.run()                      │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  BrowserApp.startup()                 │
    │  → Khởi tạo một lần duy nhất          │
    │  → Đăng ký shortcuts, resources       │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  BrowserApp.activate()                │
    │  → Tạo BrowserWindow                  │
    │  → Hiển thị cửa sổ                    │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  BrowserWindow constructor            │
    │  → Tạo UI: HeaderBar, TabView, WebView│
    │  → Thiết lập NetworkSession           │
    │  → Đăng ký message handlers           │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  GTK Main Loop                        │
    │  → Chờ sự kiện từ người dùng          │
    │  → Xử lý navigation, tabs, etc.       │
    └───────────────────────────────────────┘
                    │
             (User đóng app)
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  Cleanup và Exit                      │
    │  → Lưu dữ liệu (history, cookies)     │
    │  → Trả mã thoát cho hệ thống          │
    └───────────────────────────────────────┘
```

### 3.2. Luồng Tải Trang Web

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          LUỒNG TẢI TRANG WEB                            │
└─────────────────────────────────────────────────────────────────────────┘

    User nhập URL và nhấn Enter
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  url_entry.activate signal            │
    │  → Gọi navigate_to(url)               │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  WebView.load_uri()                   │
    │  → WebKit bắt đầu tải trang           │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  inject_autofill_script()             │
    │  → Đọc autofill.js                    │
    │  → Inject vào trang                   │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  load_changed signal (FINISHED)       │
    │  → Cập nhật title, url_entry          │
    │  → Thêm vào lịch sử                   │
    └───────────────────────────────────────┘
```

### 3.3. Luồng Lưu Mật Khẩu

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          LUỒNG LƯU MẬT KHẨU                             │
└─────────────────────────────────────────────────────────────────────────┘

    User nhập username/password và submit form
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  autofill.js: handleSubmission()      │
    │  → Thu thập username, password, url   │
    │  → Gửi qua webkit.messageHandlers     │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  window.vala: on_password_message()   │
    │  → Parse JSON message                 │
    │  → Kiểm tra đã lưu chưa               │
    └───────────────────────────────────────┘
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  Hiển thị Dialog "Lưu mật khẩu?"      │
    │  User chọn Yes hoặc No                │
    └───────────────────────────────────────┘
                    │
              (User chọn Yes)
                    │
                    ▼
    ┌───────────────────────────────────────┐
    │  CredentialManager.save_credential()  │
    │  → Ghép username + password           │
    │  → Lưu vào GNOME Keyring              │
    └───────────────────────────────────────┘
```

---

## 🚀 4. Bắt Đầu Từ Đâu? (Getting Started)

### 4.1. Yêu Cầu Hệ Thống

- **OS**: Linux (GNOME Desktop được khuyến nghị)
- **Dependencies**: GTK4, Libadwaita, WebKitGTK 6, JSON-GLib, Libsecret
- **Build Tools**: Meson, Ninja, Vala Compiler

### 4.2. Cài Đặt Dependencies

**Fedora/RHEL:**
```bash
sudo dnf install gtk4-devel libadwaita-devel webkitgtk6.0-devel \
                 json-glib-devel libsecret-devel vala meson ninja-build
```

**Ubuntu/Debian:**
```bash
sudo apt install libgtk-4-dev libadwaita-1-dev libwebkitgtk-6.0-dev \
                 libjson-glib-dev libsecret-1-dev valac meson ninja-build
```

**Arch Linux:**
```bash
sudo pacman -S gtk4 libadwaita webkitgtk-6.0 json-glib libsecret \
               vala meson ninja
```

### 4.3. Build và Chạy

```bash
# Bước 1: Clone hoặc tải dự án
cd /path/to/my_browser

# Bước 2: Cấu hình build (chỉ cần làm lần đầu)
meson setup build

# Bước 3: Biên dịch
ninja -C build

# Bước 4: Chạy ứng dụng
./build/app/my-browser
```

### 4.4. Quy Trình Phát Triển Đề Xuất

```
┌─────────────────────────────────────────────────────────────────────────┐
│                       QUY TRÌNH PHÁT TRIỂN                              │
└─────────────────────────────────────────────────────────────────────────┘

   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │ 1. Đọc code │ ──▶ │ 2. Sửa code │ ──▶ │ 3. Build    │
   │    hiện tại │     │    .vala    │     │    ninja    │
   └─────────────┘     └─────────────┘     └──────┬──────┘
                                                  │
                                                  ▼
   ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
   │ 6. Commit   │ ◀── │ 5. Sửa lỗi  │ ◀── │ 4. Test     │
   │    thay đổi │     │    nếu có   │     │    thủ công │
   └─────────────┘     └─────────────┘     └─────────────┘
```

**Lời khuyên cho người mới:**

1. **Bắt đầu nhỏ**: Thử thay đổi title của cửa sổ trong `window.vala`
2. **Theo dõi log**: Chạy từ terminal để xem các message() logs
3. **Đọc comments**: Mọi file đều có comments chi tiết bằng tiếng Việt
4. **Thử nghiệm**: Không sợ phá vỡ code, bạn có thể rebuild lại

---

## 📖 5. Hướng Dẫn Chi Tiết Từng File

### 5.1. `meson.build` (Root) - Cấu Hình Build Chính

**Vị trí**: `/my_browser/meson.build`

**Mục đích**: Định nghĩa thông tin dự án và các thư viện phụ thuộc.

**Nội dung chính:**
```meson
# Định nghĩa dự án
project('my_browser', 'vala', 'c',
  version: '0.1.0',
  meson_version: '>= 0.59.0',
)

# Khai báo dependencies
deps = [
  dependency('gtk4'),           # UI toolkit cơ bản
  dependency('libadwaita-1'),   # GNOME theme
  dependency('webkitgtk-6.0'),  # Web engine
  dependency('json-glib-1.0'),  # JSON processing
  dependency('libsecret-1'),    # Password storage
]

# Xử lý subdirectory với security flags
subdir('app')
```

**📝 Lưu ý:** File `app/meson.build` chứa cấu hình security hardening flags:
- `-fstack-protector-strong`: Stack canary protection
- `-D_FORTIFY_SOURCE=2`: Buffer overflow detection
- `-Wl,-z,relro,-z,now`: Full RELRO
- `-pie`: Position Independent Executable

---

### 5.2. `main.vala` - Entry Point

**Vị trí**: `/my_browser/app/main.vala`

**Mục đích**: Điểm vào của chương trình, khởi tạo Application object.

**Kiến trúc:**
```
┌─────────────────────────────────────────────────────────────────────────┐
│  BrowserApp : Adw.Application                                           │
│  ├── startup()   → Khởi tạo một lần duy nhất                           │
│  ├── activate()  → Tạo và hiển thị cửa sổ                              │
│  └── main()      → Entry point, tạo app và chạy                        │
└─────────────────────────────────────────────────────────────────────────┘
```

**Luồng thực thi:**
1. `main()` được gọi khi chạy `./my-browser`
2. Tạo `BrowserApp` instance
3. `app.run()` bắt đầu vòng lặp GTK
4. `startup()` được gọi một lần
5. `activate()` được gọi để hiển thị cửa sổ

---

### 5.3. `window.vala` - Cửa Sổ Chính

**Vị trí**: `/my_browser/app/window.vala`

**Mục đích**: File quan trọng nhất, chứa toàn bộ UI và logic của trình duyệt.

**Cấu trúc UI:**
```
┌─────────────────────────────────────────────────────────────────────────┐
│ BrowserWindow                                                           │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ HeaderBar                                                           │ │
│ │ [←] [→] [↻] [____URL Entry____________________________] [≡]        │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ TabBar                                                              │ │
│ │ [Tab 1: Google] [Tab 2: Facebook] [+]                               │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │ TabView                                                             │ │
│ │ ┌─────────────────────────────────────────────────────────────────┐ │ │
│ │ │ WebView (Hiển thị nội dung trang web)                           │ │ │
│ │ │                                                                 │ │ │
│ │ │                    [Nội dung Web]                               │ │ │
│ │ │                                                                 │ │ │
│ │ └─────────────────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

**Các thành phần chính:**

| Widget | Vai trò |
|--------|---------|
| `HeaderBar` | Thanh tiêu đề với các nút điều khiển |
| `back_button` | Nút quay lại trang trước |
| `forward_button` | Nút đi tới trang tiếp |
| `refresh_button` | Nút tải lại trang |
| `url_entry` | Ô nhập địa chỉ URL |
| `menu_button` | Nút menu (history, settings) |
| `TabView` | Container quản lý nhiều tabs |
| `TabBar` | Thanh hiển thị các tabs |
| `WebView` | Widget hiển thị trang web (WebKitGTK) |

**Các chức năng quan trọng:**

| Hàm | Chức năng | Security |
|-----|-----------|----------|
| `get_network_session()` | Khởi tạo session với cookie persistence + third-party blocking | 🔒 Cookie policy |
| `create_web_view()` | Tạo WebView mới với autofill.js injection | 🔒 File access restrictions |
| `navigate_to()` | Điều hướng đến URL | 🔒 URL scheme validation |
| `add_new_tab()` | Thêm tab mới | ✅ Isolated WebView |
| `on_password_message()` | Xử lý tin nhắn từ JavaScript | 🔒 IPC validation, token generation |
| `inject_autofill_script()` | Inject autofill.js vào trang web | ✅ Content script injection |
| `on_tls_error()` | Xử lý lỗi SSL/TLS certificate | 🔒 User warnings, secure defaults |

---

### 5.4. `credential_manager.vala` - Quản Lý Mật Khẩu

**Vị trí**: `/my_browser/app/credential_manager.vala`

**Mục đích**: Lưu trữ và truy xuất mật khẩu một cách an toàn.

**Sử dụng Singleton Pattern:**
```vala
// Chỉ có MỘT instance trong toàn ứng dụng
var manager = CredentialManager.get_default();
manager.save_credential(url, username, password);
```

**API chính:**

| Phương thức | Mô tả |
|-------------|-------|
| `get_default()` | Lấy instance duy nhất (Singleton) |
| `save_credential(url, username, password)` | Lưu mật khẩu vào Keyring |
| `get_credential_sync(url)` | Lấy mật khẩu đã lưu cho URL |
| `has_credential(url, username)` | Kiểm tra đã có mật khẩu chưa |

---

### 5.5. `history_manager.vala` - Quản Lý Lịch Sử

**Vị trí**: `/my_browser/app/history_manager.vala`

**Mục đích**: Lưu trữ và quản lý lịch sử duyệt web.

**Cấu trúc dữ liệu:**
```json
[
  {
    "url": "https://www.google.com",
    "title": "Google",
    "timestamp": "2026-01-20T22:00:00+07:00"
  },
  {
    "url": "https://www.facebook.com",
    "title": "Facebook",
    "timestamp": "2026-01-20T21:30:00+07:00"
  }
]
```

**Vị trí lưu trữ:** `~/.local/share/my-browser/history.json`

**API chính:**

| Phương thức | Mô tả |
|-------------|-------|
| `get_default()` | Lấy instance duy nhất |
| `add(url, title)` | Thêm trang vào lịch sử |
| `get_all()` | Lấy toàn bộ lịch sử |
| `clear()` | Xóa toàn bộ lịch sử |

---

### 5.6. `history_dialog.vala` - Dialog Hiển Thị Lịch Sử

**Vị trí**: `/my_browser/app/history_dialog.vala`

**Mục đích**: Hiển thị danh sách lịch sử duyệt web cho người dùng.

**Luồng sử dụng:**
```
User click Menu → History        HistoryDialog hiển thị
        ↓                               ↓
┌─────────────────┐              ┌─────────────────────────┐
│  Menu Button    │   ────▶      │  ┌───────────────────┐  │
└─────────────────┘              │  │ Google      22:00 │  │
                                 │  ├───────────────────┤  │
                                 │  │ Facebook    21:30 │  │
                                 │  └───────────────────┘  │
                                 └─────────────────────────┘
                                          ↓
                                  User click vào row
                                          ↓
                                  Signal: open_url(url)
                                          ↓
                                  window.vala mở tab mới
```

---

### 5.7. `autofill.js` - JavaScript Injection

**Vị trí**: `/my_browser/app/autofill.js`

**Mục đích**: Script được inject vào mọi trang web để phát hiện và xử lý form đăng nhập.

**Các chức năng:**

| Chức năng | Mô tả | Security |
|-----------|-------|----------|
| Phát hiện form login | Theo dõi submit, keydown Enter, click button | ✅ Heuristic-based detection |
| Thu thập credentials | Lấy username và password từ form | ✅ Field length validation |
| Giao tiếp với Vala | Gửi message qua `webkit.messageHandlers` | ✅ JSON serialization, size limits |
| Tự động điền (Secure) | Gọi `fillCredentialsSecure()` với token verification | 🔒 One-time token, XSS protection |
| Popup credentials | Hiển thị danh sách credentials đã lưu | ✅ Safe rendering, no sensitive logs |

**Giao tiếp JavaScript ↔ Vala:**
```javascript
// ============================================================================
// 1. JavaScript gửi tin nhắn đến Vala
// ============================================================================
window.webkit.messageHandlers.password_manager.postMessage(
    JSON.stringify({
        action: 'save_password',
        username: 'user@example.com',
        password: '***',
        url: 'https://example.com/login'
    })
);

// ============================================================================
// 2. Vala gọi hàm JavaScript với Security Token (XSS Protection)
// ============================================================================
// (Trong window.vala - Secure autofill mechanism)

// Bước 1: Tạo security token (random, one-time use)
string token = "%lld_%d".printf(GLib.get_real_time(), GLib.Random.int_range(1000, 9999));

// Bước 2: Encode credentials bằng JSON (tránh injection)
var builder = new Json.Builder();
builder.begin_object();
builder.set_member_name("u");
builder.add_string_value(cred.username);
builder.set_member_name("p");
builder.add_string_value(cred.password);
builder.end_object();
string json_data = generator.to_data(null);

// Bước 3: Set token và fill credentials
string set_token_js = "window._setAutofillToken('%s');".printf(token);
string fill_js = "(function() { var d = %s; window.fillCredentialsSecure(d.u, d.p, '%s'); })();".printf(json_data, token);
web_view.evaluate_javascript.begin(set_token_js + fill_js, ...);
```

**Cơ chế bảo mật:**
- 🔒 **Token verification**: Mỗi lần fill credentials dùng token riêng biệt
- 🔒 **One-time token**: Token bị xóa ngay sau khi sử dụng
- 🔒 **JSON encoding**: Không thể injection qua special characters
- 🔒 **No sensitive logging**: Đã xóa tất cả console.log chứa thông tin nhạy cảm

---

## 🔐 6. Hệ Thống Password Manager

### 6.1. Kiến Trúc Tổng Quan

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          TRANG WEB                                       │
│  ┌─────────────────────────────────────────────────────────────────────┐│
│  │  Form đăng nhập: [Username] [Password] [Login Button]               ││
│  └─────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (1) JavaScript phát hiện đăng nhập
┌─────────────────────────────────────────────────────────────────────────┐
│                        autofill.js (Frontend)                            │
│  - Theo dõi sự kiện: submit, click, keydown                             │
│  - Thu thập username/password                                           │
│  - Gửi tin nhắn đến Vala qua webkit.messageHandlers                     │
│  - 🔒 Token verification để điền credentials an toàn                    │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (2) Giao tiếp JS ↔ Vala với IPC validation
┌─────────────────────────────────────────────────────────────────────────┐
│                        window.vala (Backend)                             │
│  - ✅ IPC message validation (size, action whitelist, field lengths)    │
│  - Nhận tin nhắn JSON từ JavaScript                                     │
│  - Hiển thị dialog "Lưu mật khẩu?"                                      │
│  - 🔒 Generate random security token                                    │
│  - 🔒 JSON encode credentials (tránh injection)                         │
│  - Gọi CredentialManager để lưu/lấy mật khẩu                            │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ (3) Lưu trữ an toàn với mã hóa
┌─────────────────────────────────────────────────────────────────────────┐
│                   credential_manager.vala (Storage)                      │
│  - Sử dụng thư viện libsecret                                           │
│  - Lưu vào GNOME Keyring (mã hóa bởi hệ thống)                          │
│  - 🔒 Credentials được mã hóa với user's login password                 │
└─────────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    GNOME Keyring / Secret Service                        │
│  - Mã hóa mật khẩu bằng khóa của user                                   │
│  - Lưu trữ trong file database của hệ thống                             │
│  - Tự động mở khóa khi user đăng nhập vào máy                           │
└─────────────────────────────────────────────────────────────────────────┘
```

### 6.2. Các Actions Và Security Measures

| Action | Mô tả | Security Measures | Trigger |
|--------|-------|-------------------|---------|
| `save_password` | Yêu cầu lưu mật khẩu mới | ✅ Field length validation<br>✅ Message size check | User submit form đăng nhập |
| `request_credentials` | Yêu cầu lấy mật khẩu đã lưu | ✅ URL validation<br>✅ Action whitelist | User focus vào ô input |
| `fill_credential` | Điền mật khẩu vào form | ✅ Token verification<br>✅ JSON encoding<br>✅ One-time use | User chọn credential từ popup |

### 6.3. Security Flow Chi Tiết

**Flow 1: Lưu Mật Khẩu (Save Password)**
```
1. autofill.js phát hiện form submission
2. Thu thập username + password
3. Gửi IPC message đến window.vala
4. window.vala validate message:
   - Check message size (< 10KB)
   - Validate action in whitelist
   - Check username length (< 255 chars)
   - Check password length (< 1024 chars)
5. Hiển thị dialog xác nhận
6. Nếu user chọn "Yes" → Lưu vào GNOME Keyring
```

**Flow 2: Điền Mật Khẩu (Autofill) - SECURE**
```
1. User focus vào ô input
2. autofill.js gửi request_credentials
3. window.vala lấy credentials từ Keyring
4. Generate random security token
5. window.vala gọi JavaScript:
   - Set token: window._setAutofillToken(token)
   - Fill với verification: fillCredentialsSecure(user, pass, token)
6. autofill.js verify token trước khi fill
7. Token bị xóa ngay sau khi dùng (one-time)
```

---

## 🍪 7. Hệ Thống Session & Cookie

### 7.1. Cookie Là Gì?

Cookie là đoạn dữ liệu nhỏ mà website lưu trên máy bạn để "nhớ" bạn.

```
┌─────────────────────────────────────────────────────────────────────────┐
│ VÍ DỤ VỀ COOKIE                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Name:     session_id                                                    │
│ Value:    abc123xyz789                                                  │
│ Domain:   .facebook.com                                                 │
│ Path:     /                                                             │
│ Expires:  2026-02-20T00:00:00Z                                          │
│ HttpOnly: true                                                          │
│ Secure:   true                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 7.2. Cách My Browser Xử Lý

```vala
// Trong window.vala
private static NetworkSession get_network_session() {
    // Thư mục lưu trữ data
    string data_dir = Path.build_filename(
        Environment.get_user_data_dir(),  // ~/.local/share/
        "my-browser"
    );
    
    // Thư mục cache
    string cache_dir = Path.build_filename(
        Environment.get_user_cache_dir(),  // ~/.cache/
        "my-browser"
    );
    
    // Tạo NetworkSession với persistent storage
    shared_network_session = new NetworkSession(data_dir, cache_dir);
    
    // Cấu hình cookie storage
    var cookie_manager = shared_network_session.get_cookie_manager();
    string cookie_file = Path.build_filename(data_dir, "cookies.sqlite");
    cookie_manager.set_persistent_storage(cookie_file, CookiePersistentStorage.SQLITE);
}
```

### 7.3. Vị Trí Lưu Trữ Dữ Liệu

```
~/.local/share/my-browser/          # Thư mục DATA
├── cookies.sqlite                  # File SQLite chứa cookies
├── history.json                    # Lịch sử duyệt web
├── databases/                      # IndexedDB databases
└── localstorage/                   # Local Storage

~/.cache/my-browser/                # Thư mục CACHE
├── http-cache/                     # HTTP cache (hình ảnh, CSS, JS)
└── webgl-cache/                    # WebGL shader cache
```

---

## 🕐 8. Hệ Thống Lịch Sử Duyệt Web

### 8.1. Luồng Hoạt Động

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    LUỒNG GHI LỊCH SỬ                                    │
└─────────────────────────────────────────────────────────────────────────┘

    Trang web load xong
           │
           ▼
    ┌──────────────────────────────────────┐
    │  WebView: load_changed (FINISHED)    │
    └──────────────────────────────────────┘
           │
           ▼
    ┌──────────────────────────────────────┐
    │  window.vala gọi:                    │
    │  HistoryManager.get_default()        │
    │      .add(url, title)                │
    └──────────────────────────────────────┘
           │
           ▼
    ┌──────────────────────────────────────┐
    │  history_manager.vala:               │
    │  - Tạo HistoryItem                   │
    │  - Thêm vào đầu mảng                 │
    │  - Ghi JSON vào file                 │
    └──────────────────────────────────────┘
           │
           ▼
    ┌──────────────────────────────────────┐
    │  ~/.local/share/my-browser/          │
    │      history.json                    │
    └──────────────────────────────────────┘
```

### 8.2. File `history.json`

```json
[
  {
    "url": "https://www.google.com/search?q=vala",
    "title": "vala - Google Search",
    "timestamp": "2026-01-20T22:50:00+07:00"
  },
  {
    "url": "https://wiki.gnome.org/Projects/Vala",
    "title": "Vala - GNOME Wiki",
    "timestamp": "2026-01-20T22:45:00+07:00"
  }
]
```

---

## � 9. Bảo Mật (Security)

### 9.1. Tổng Quan Bảo Mật

**My Browser** đã triển khai nhiều lớp bảo vệ để đảm bảo an toàn cho người dùng:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SECURITY LAYERS                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  Layer 1: Compiler Security (BUILD TIME)                                │
│  ├─ Stack canaries (-fstack-protector-strong)                           │
│  ├─ Buffer overflow checks (-D_FORTIFY_SOURCE=2)                        │
│  ├─ Full RELRO (-Wl,-z,relro,-z,now)                                    │
│  └─ PIE for ASLR (-pie)                                                 │
│                                                                          │
│  Layer 2: Runtime Security                                              │
│  ├─ Process isolation (WebKitGTK multi-process)                         │
│  ├─ File access restrictions                                            │
│  ├─ TLS certificate validation                                          │
│  └─ URL scheme filtering                                                │
│                                                                          │
│  Layer 3: Data Security                                                 │
│  ├─ GNOME Keyring for passwords                                         │
│  ├─ XSS token verification                                              │
│  ├─ Third-party cookie blocking                                         │
│  └─ IPC message validation                                              │
│                                                                          │
│  Layer 4: Production Hardening                                          │
│  └─ Conditional developer tools                                         │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 9.2. Security Features Chi Tiết

#### 9.2.1. Compiler Security Flags

Tất cả builds đều áp dụng các flags bảo mật sau (trong `app/meson.build`):

```meson
c_args: [
  '-fstack-protector-strong',  # Stack canary protection
  '-D_FORTIFY_SOURCE=2',       # Runtime buffer overflow checks
  '-Wformat',                   # Format string checking
  '-Werror=format-security',    # Format security errors
],
link_args: [
  '-Wl,-z,relro',              # Relocation Read-Only
  '-Wl,-z,now',                # Immediate binding
  '-pie',                       # Position Independent Executable
]
```

#### 9.2.2. XSS Protection

Password autofill sử dụng one-time token verification:

```javascript
// autofill.js
window._setAutofillToken = function(token) {
    _securityToken = token;
};

function fillCredentials(username, password, token) {
    if (token !== _securityToken || _securityToken === null) {
        console.warn("[Security] Invalid token");
        return;
    }
    _securityToken = null;  // One-time use
    // ... fill credentials
}
```

#### 9.2.3. IPC Message Validation

Strict validation cho messages từ JavaScript:

```vala
// window.vala
private static void on_password_message(...) {
    // Message size validation
    if (msg.length > 10000) {
        warning("Message too large");
        return;
    }
    
    // Action whitelist
    if (action != "save_password" && 
        action != "request_credentials" && 
        action != "fill_credential") {
        warning("Invalid action: %s", action);
        return;
    }
    
    // Field length validation
    if (username.length > 255 || password.length > 1024) {
        warning("Field length validation failed");
        return;
    }
}
```

#### 9.2.4. URL Scheme Filtering

Block dangerous URL schemes:

```vala
if (url.has_prefix("javascript:") || 
    url.has_prefix("data:") || 
    url.has_prefix("vbscript:")) {
    warning("[Security] Blocked dangerous URL scheme");
    // Show warning dialog
    return;
}
```

#### 9.2.5. TLS Error Handling

User warnings cho invalid SSL certificates:

```vala
web_view.load_failed_with_tls_errors.connect((failing_uri, certificate, errors) => {
    critical("[Security] TLS Error for %s", failing_uri);
    
    // Show warning dialog with "Go Back" (default) and "Continue Anyway"
    var dialog = new Adw.MessageDialog(...);
    dialog.set_response_appearance("continue", Adw.ResponseAppearance.DESTRUCTIVE);
});
```

### 9.3. Verification

Xác minh binary đã được hardened:

```bash
# Install verification tools (if not installed)
sudo dnf install checksec  # Fedora
sudo apt install checksec  # Ubuntu

# Check security features
checksec --file=build/app/my-browser

# hoặc
hardening-check build/app/my-browser
```

Expected output:
```
RELRO           STACK CANARY      NX            PIE
Full RELRO      Canary found      NX enabled    PIE enabled
```

### 9.4. Security Best Practices Cho Development

1. **Không commit credentials**: Không lưu passwords trong code
2. **Test in release mode**: Test cả debug và release builds
3. **Validate user input**: Always validate messages từ JavaScript
4. **Use HTTPS**: Ưu tiên HTTPS trong default URLs
5. **Review security logs**: Chú ý các warning messages

### 9.5. Known Limitations

| Issue | Impact | Mitigation |
|-------|--------|------------|
| No CSP yet | MEDIUM | Planned for future version |
| History not encrypted | LOW | Use encrypted filesystem |
| No Safe Browsing API | MEDIUM | Manual URL verification |

Chi tiết đầy đủ: [`enhance_security_version_20260121.md`](enhance_security_version_20260121.md)

---

## �🛠️ 10. Biên Dịch và Chạy Ứng Dụng

### 9.1. Lệnh Cơ Bản

```bash
# Cấu hình build (chỉ cần lần đầu)
meson setup build

# Biên dịch
ninja -C build

# Chạy ứng dụng
./build/app/my-browser
```

### 9.2. Các Lệnh Hữu Ích Khác

```bash
# Build lại sau khi sửa code
ninja -C build

# Xóa build cũ và build lại từ đầu
rm -rf build && meson setup build && ninja -C build

# Cài đặt vào hệ thống
sudo ninja -C build install

# Gỡ cài đặt
sudo ninja -C build uninstall

# Chạy với debug output
G_MESSAGES_DEBUG=all ./build/app/my-browser
```

### 9.3. Build với Security Hardening

Browser đã được cấu hình với compiler security flags. Build bình thường sẽ tự động áp dụng:

```bash
# Build thông thường (đã bao gồm security flags)
ninja -C build

# Verify security features trong binary
hardening-check build/app/my-browser
# Hoặc
checksec --file=build/app/my-browser
```

**Expected output:**
```
Stack Canary:               ✓ Enabled
Position Independent:       ✓ Enabled  
Read-only relocations:      ✓ Enabled
Immediate binding:          ✓ Enabled
```

### 9.4. Debug vs Release Builds

```bash
# Debug build (mặc định) - có Developer Tools
meson setup build
ninja -C build

# Release build - KHÔNG có Developer Tools, optimized
meson setup build --buildtype=release
ninja -C build
```

**Khác biệt giữa DEBUG và RELEASE:**

| Feature | DEBUG Build | RELEASE Build |
|---------|-------------|---------------|
| Developer Tools | ✅ Enabled | ❌ Disabled |
| Optimization | ❌ None (-O0) | ✅ Full (-O2) |
| Stack Protection | ✅ Yes | ✅ Yes |
| Binary Size | Lớn hơn | Nhỏ hơn |
| Performance | Chậm hơn | Nhanh hơn |

### 9.5. Debug Tips

```bash
# Xem tất cả log messages
G_MESSAGES_DEBUG=all ./build/app/my-browser

# Chỉ xem log từ ứng dụng
G_MESSAGES_DEBUG=my-browser ./build/app/my-browser

# Xem JavaScript console output (trong terminal)
# Các lỗi JavaScript sẽ hiện trong terminal khi chạy app

# Kiểm tra cookies đã lưu
sqlite3 ~/.local/share/my-browser/cookies.sqlite "SELECT * FROM cookies;"

# Xem lịch sử
cat ~/.local/share/my-browser/history.json | python3 -m json.tool
```

---

## 📚 10. Tài Liệu Tham Khảo

### 10.1. Tài Liệu Chính Thức

| Chủ đề | Link |
|--------|------|
| Vala Tutorial | https://wiki.gnome.org/Projects/Vala/Tutorial |
| GTK4 Documentation | https://docs.gtk.org/gtk4/ |
| Libadwaita Docs | https://gnome.pages.gitlab.gnome.org/libadwaita/ |
| WebKitGTK Reference | https://webkitgtk.org/reference/webkit2gtk/stable/ |
| Libsecret Docs | https://gnome.pages.gitlab.gnome.org/libsecret/ |
| JSON-GLib Docs | https://gnome.pages.gitlab.gnome.org/json-glib/ |

### 10.2. Học Thêm

- **GNOME Developer Documentation**: https://developer.gnome.org/
- **Vala API Reference**: https://valadoc.org/
- **Meson Build System**: https://mesonbuild.com/

---

## 🎉 Kết Luận

Chúc mừng bạn đã đọc đến đây! Bây giờ bạn đã có cái nhìn tổng quan về:

- ✅ Cấu trúc dự án và vai trò của từng file
- ✅ Luồng hoạt động của ứng dụng
- ✅ Cách Password Manager hoạt động
- ✅ Cách Session/Cookie được lưu trữ
- ✅ Cách lịch sử duyệt web được quản lý
- ✅ Cách biên dịch và chạy ứng dụng

**Bước tiếp theo?**
1. Đọc code trong từng file (bắt đầu từ `main.vala`)
2. Thử sửa đổi nhỏ và build lại
3. Thêm tính năng mới theo ý của bạn

Chúc bạn học tập vui vẻ và phát triển thêm nhiều tính năng thú vị! 🚀

# my_browser
Vibe code to create a my browser
