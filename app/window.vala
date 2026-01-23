// =============================================================================
// FILE: window.vala - CỬA SỔ TRÌNH DUYỆT CHÍNH
// =============================================================================
//
// 📚 KIẾN THỨC NỀN TẢNG:
// -----------------------
// 1. WEBKIT là gì?
//    - WebKit là engine render web (hiển thị HTML/CSS/JS)
//    - Được dùng bởi Safari, GNOME Web, và nhiều trình duyệt khác
//    - WebKitGTK là binding của WebKit cho GTK
//
// 2. TABVIEW là gì?
//    - Widget quản lý nhiều tabs (như Chrome, Firefox)
//    - Mỗi tab chứa một WebView (một trang web)
//    - Có thể kéo thả, đóng, thêm tab mới
//
// 3. SIGNAL & CALLBACKS là gì?
//    - Signal: Thông báo sự kiện (VD: "clicked", "notify::uri")
//    - Callback: Hàm được gọi khi signal được emit
//    - connect(): Đăng ký callback cho signal
//
// 4. SCRIPT INJECTION là gì?
//    - Tiêm mã JavaScript vào trang web
//    - Cho phép mở rộng chức năng trang web
//    - VD: Autofill passwords, block ads, modify content
//
// =============================================================================
//
// 📊 SƠ ĐỒ CẤU TRÚC GIAO DIỆN:
//
// ┌─────────────────────────────────────────────────────────────────────────┐
// │ BrowserWindow (Adw.ApplicationWindow)                                  │
// │ ┌─────────────────────────────────────────────────────────────────────┐│
// │ │ ToolbarView                                                         ││
// │ │ ┌─────────────────────────────────────────────────────────────────┐││
// │ │ │ HeaderBar                                                       │││
// │ │ │ [←][→][↻]  [________________URL Entry________________] [+][📜] │││
// │ │ ├─────────────────────────────────────────────────────────────────┤││
// │ │ │ TabBar                                                          │││
// │ │ │ [Tab 1: Google] [Tab 2: Facebook] [+]                          │││
// │ │ ├─────────────────────────────────────────────────────────────────┤││
// │ │ │ TabView (content area)                                          │││
// │ │ │ ┌─────────────────────────────────────────────────────────────┐│││
// │ │ │ │ WebView (hiển thị trang web hiện tại)                       ││││
// │ │ │ │                                                             ││││
// │ │ │ │   [Nội dung trang web...]                                   ││││
// │ │ │ │                                                             ││││
// │ │ │ └─────────────────────────────────────────────────────────────┘│││
// │ │ └─────────────────────────────────────────────────────────────────┘││
// │ └─────────────────────────────────────────────────────────────────────┘│
// └─────────────────────────────────────────────────────────────────────────┘
//
// =============================================================================

// -----------------------------------------------------------------------------
// PHẦN 1: IMPORT THƯ VIỆN
// -----------------------------------------------------------------------------

using Gtk;       // Thư viện đồ họa cơ bản (Button, Entry, Box...)
using Adw;       // Thư viện Adwaita (HeaderBar, TabView, Window...)
using WebKit;    // Thư viện WebKitGTK (WebView để hiển thị web)

// -----------------------------------------------------------------------------
// PHẦN 2: CLASS BROWSERWINDOW - Định nghĩa cửa sổ trình duyệt
// -----------------------------------------------------------------------------
//
// Thừa kế từ Adw.ApplicationWindow
// ApplicationWindow: Cửa sổ thuộc về một Application, có thêm nhiều tính năng
//

public class BrowserWindow : Adw.ApplicationWindow {
    // =========================================================================
    // BIẾN INSTANCE (Instance Variables / Fields)
    // =========================================================================
    //
    // Các widget chính của cửa sổ
    // private: Chỉ class này mới truy cập được
    //
    
    // TabView: Quản lý các tabs
    private Adw.TabView tab_view;
    
    // TabBar: Thanh hiển thị các tabs (có thể click để chuyển tab)
    private Adw.TabBar tab_bar;
    
    // Entry: Ô nhập URL
    private Entry url_entry;
    
    // Buttons: Các nút điều hướng
    private Button back_button;      // Nút quay lại
    private Button forward_button;   // Nút đi tiếp
    private Button reload_button;    // Nút reload trang
    
    // URL Autocomplete
    private Popover completion_popover;
    private ListBox completion_list;
    
    // =========================================================================
    // NETWORK SESSION - Quản lý kết nối mạng và dữ liệu persistent
    // =========================================================================
    //
    // static: Shared giữa TẤT CẢ các instances của BrowserWindow
    // Tại sao? Để tất cả các tabs/windows share cùng:
    //   - Cookies
    //   - Local Storage
    //   - Cache
    //   - Session data
    //
    private static NetworkSession? shared_network_session = null;
    
    // -------------------------------------------------------------------------
    // HÀM LẤY NETWORK SESSION (Lazy Initialization)
    // -------------------------------------------------------------------------
    //
    // Lazy init: Chỉ tạo khi cần, không tạo ngay từ đầu
    // Tại sao? NetworkSession cần I/O operations (tạo thư mục, đọc file)
    //          Nếu tạo sớm có thể gây slowdown khởi động
    //
    private static NetworkSession get_network_session() {
        if (shared_network_session == null) {
            // -----------------------------------------------------------------
            // XÁC ĐỊNH THƯ MỤC LƯU TRỮ
            // -----------------------------------------------------------------
            //
            // Data directory: Lưu trữ dữ liệu người dùng (cần backup)
            //   - cookies.sqlite
            //   - localstorage/
            //   - databases/
            //
            // Cache directory: Lưu trữ cache (có thể xóa mà không mất dữ liệu)
            //   - HTTP cache (images, CSS, JS)
            //
            string data_dir = Path.build_filename(
                Environment.get_user_data_dir(),   // ~/.local/share
                "my-browser"                       // Tên ứng dụng
            );
            string cache_dir = Path.build_filename(
                Environment.get_user_cache_dir(),  // ~/.cache
                "my-browser"
            );
            
            // Tạo thư mục nếu chưa tồn tại
            // 0755 = rwxr-xr-x (owner full, group/others read+execute)
            DirUtils.create_with_parents(data_dir, 0755);
            DirUtils.create_with_parents(cache_dir, 0755);
            
            // Log để debug
            message("Data directory: %s", data_dir);
            message("Cache directory: %s", cache_dir);
            
            // -----------------------------------------------------------------
            // TẠO NETWORK SESSION
            // -----------------------------------------------------------------
            //
            // NetworkSession quản lý:
            //   - CookieManager: Cookies
            //   - WebsiteDataManager: Local Storage, IndexedDB, Cache
            //   - NetworkProcess: Kết nối mạng
            //
            // Truyền data_dir và cache_dir để dữ liệu được lưu vĩnh viễn
            //
            shared_network_session = new NetworkSession(data_dir, cache_dir);
            
            // -----------------------------------------------------------------
            // NOTE: Process Sandboxing
            // -----------------------------------------------------------------
            //
            // WebKitGTK 6.0's NetworkSession API doesn't expose process model configuration
            // Process isolation is handled internally by WebKitGTK
            // Each WebView automatically uses separate processes for rendering
            //
            message("WebKitGTK handles process isolation automatically");
            
            // -----------------------------------------------------------------
            // CẤU HÌNH COOKIE MANAGER
            // -----------------------------------------------------------------
            //
            // CookieManager quản lý việc lưu trữ và gửi cookies
            //
            var cookie_manager = shared_network_session.get_cookie_manager();
            
            // Đường dẫn file SQLite để lưu cookies
            string cookie_file = Path.build_filename(data_dir, "cookies.sqlite");
            
            // Cấu hình persistent storage
            // CookiePersistentStorage.SQLITE: Dùng SQLite database
            //   - Bền vững (survive restart)
            //   - Nhanh (indexed queries)
            //   - Reliable (ACID transactions)
            //
            cookie_manager.set_persistent_storage(cookie_file, CookiePersistentStorage.SQLITE);
            
            // -----------------------------------------------------------------
            // SECURITY: Block third-party cookies (tracking protection)
            // -----------------------------------------------------------------
            //
            // CookieAcceptPolicy.NO_THIRD_PARTY:
            //   - Chỉ accept cookies từ domain chính
            //   - Block cookies từ third-party domains (tracking, ads)
            //
            cookie_manager.set_accept_policy(CookieAcceptPolicy.NO_THIRD_PARTY);
            message("Cookie policy: NO_THIRD_PARTY (blocking tracking cookies)");
            
            message("Cookie file: %s", cookie_file);
        }
        return shared_network_session;
    }

    // =========================================================================
    // CONSTRUCTOR - Khởi tạo cửa sổ trình duyệt
    // =========================================================================
    //
    // Tham số:
    //   - app: Application object (BrowserApp từ main.vala)
    //
    public BrowserWindow(Gtk.Application app) {
        // Gọi constructor cha với các properties
        Object(
            application: app,        // Thuộc về application nào
            title: "My Browser",     // Tiêu đề cửa sổ
            default_width: 1200,
            default_height: 800,
            resizable: true,
            visible: true            // QUAN TRỌNG: Đảm bảo window hiển thị
        );
        
        message("BrowserWindow constructor started");
        message("Application ID: %s", app.application_id ?? "null");
        
        // Force window properties for Wayland/Hyprland
        this.set_startup_id("my-browser");
        this.set_decorated(true);
        this.set_deletable(true);

        // -----------------------------------------------------------------
        // TẠO LAYOUT CHÍNH (ToolbarView)
        // -----------------------------------------------------------------
        //
        // ToolbarView: Container đặc biệt của Adwaita
        //   - Có top bar (HeaderBar)
        //   - Có bottom bar (optional)
        //   - Có content area (chính giữa)
        //
        var toolbar_view = new Adw.ToolbarView();
        this.set_content(toolbar_view);

        // -----------------------------------------------------------------
        // TẠO HEADER BAR
        // -----------------------------------------------------------------
        //
        var header_bar = new Adw.HeaderBar();
        toolbar_view.add_top_bar(header_bar);

        // -----------------------------------------------------------------
        // TẠO CÁC NÚT ĐIỀU HƯỚNG (Navigation Buttons)
        // -----------------------------------------------------------------
        //
        // Button.from_icon_name(): Tạo button với icon
        // Icon names theo FreeDesktop Icon Naming Spec:
        //   - go-previous-symbolic: Mũi tên trái
        //   - go-next-symbolic: Mũi tên phải  
        //   - view-refresh-symbolic: Icon refresh
        //   - tab-new-symbolic: Icon tab mới
        //
        back_button = new Button.from_icon_name("go-previous-symbolic");
        back_button.tooltip_text = "Back";        // Tooltip khi hover
        
        forward_button = new Button.from_icon_name("go-next-symbolic");
        forward_button.tooltip_text = "Forward";
        
        reload_button = new Button.from_icon_name("view-refresh-symbolic");
        reload_button.tooltip_text = "Reload";

        // Nhóm các nút navigation vào một Box
        // Box: Container xếp widgets theo hàng (HORIZONTAL) hoặc cột (VERTICAL)
        var nav_box = new Box(Orientation.HORIZONTAL, 0);  // 0 = no spacing
        
        // CSS class "linked": Kết nối visually các buttons
        //   → Buttons trông như một nhóm liền mạch
        nav_box.add_css_class("linked");
        
        // Thêm buttons vào box
        nav_box.append(back_button);
        nav_box.append(forward_button);
        nav_box.append(reload_button);
        
        // Đặt nav_box ở bên trái header bar
        header_bar.pack_start(nav_box);

        // -----------------------------------------------------------------
        // TẠO Ô NHẬP URL VỚI AUTOCOMPLETE
        // -----------------------------------------------------------------
        //
        // Entry: Widget nhập text một dòng
        //
        url_entry = new Entry();
        url_entry.placeholder_text = "Enter URL...";  // Text placeholder
        url_entry.hexpand = true;                      // Mở rộng theo chiều ngang
        
        // -----------------------------------------------------------------
        // THIẾT LẬP AUTOCOMPLETE CHO URL ENTRY (Custom Popover)
        // -----------------------------------------------------------------
        //
        // Gtk.EntryCompletion bị deprecated → Dùng Gtk.Popover + Gtk.ListBox
        //
        completion_popover = new Popover();
        completion_popover.set_parent(url_entry);
        completion_popover.autohide = false; // Đừng tự đóng khi mất focus của popover
        completion_popover.position = PositionType.BOTTOM;
        completion_popover.has_arrow = false;
        
        completion_list = new ListBox();
        completion_list.add_css_class("navigation-sidebar"); // Style đẹp hơn
        
        var completion_scroll = new ScrolledWindow();
        completion_scroll.set_policy(PolicyType.NEVER, PolicyType.AUTOMATIC);
        completion_scroll.set_child(completion_list);
        completion_scroll.set_size_request(400, 300);
        
        completion_popover.set_child(completion_scroll);
        
        // Xử lý khi user chọn một mục trong list
        completion_list.row_activated.connect((row) => {
            var action_row = row as Adw.ActionRow;
            if (action_row != null) {
                url_entry.text = action_row.subtitle; // subtitle lưu URL thật
                url_entry.activate();
                completion_popover.popdown();
            }
        });
        
        // -----------------------------------------------------------------
        // CẬP NHẬT GỢI Ý KHI USER GÕ
        // -----------------------------------------------------------------
        //
        // Signal changed: Khi text trong entry thay đổi
        //
        url_entry.changed.connect(() => {
            update_url_completions();
        });
        
        // -----------------------------------------------------------------
        // XỬ LÝ KEYBOARD NAVIGATION CHO AUTOCOMPLETE
        // -----------------------------------------------------------------
        //
        // Key event controller để bắt phím mũi tên và Escape
        //
        var key_controller = new Gtk.EventControllerKey();
        url_entry.add_controller(key_controller);
        
        key_controller.key_pressed.connect((keyval, keycode, state) => {
            // Escape: Đóng suggestions
            if (keyval == Gdk.Key.Escape) {
                completion_popover.popdown();
                return true;
            }
            
            // Nếu popover không hiện, không xử lý arrow keys
            if (!completion_popover.visible) {
                return false;
            }
            
            // Arrow Down: Chọn suggestion tiếp theo
            if (keyval == Gdk.Key.Down) {
                var selected = completion_list.get_selected_row();
                if (selected == null) {
                    // Chọn item đầu tiên
                    var first = completion_list.get_row_at_index(0);
                    if (first != null) {
                        completion_list.select_row(first);
                    }
                } else {
                    // Chọn item tiếp theo
                    int index = selected.get_index();
                    var next = completion_list.get_row_at_index(index + 1);
                    if (next != null) {
                        completion_list.select_row(next);
                    }
                }
                return true;
            }
            
            // Arrow Up: Chọn suggestion trước đó
            if (keyval == Gdk.Key.Up) {
                var selected = completion_list.get_selected_row();
                if (selected != null) {
                    int index = selected.get_index();
                    if (index > 0) {
                        var prev = completion_list.get_row_at_index(index - 1);
                        if (prev != null) {
                            completion_list.select_row(prev);
                        }
                    }
                }
                return true;
            }
            
            // Enter: Activate selected suggestion
            if (keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter) {
                var selected = completion_list.get_selected_row();
                if (selected != null) {
                    completion_list.row_activated(selected);
                    return true;
                }
            }
            
            return false;
        });
        
        // Ẩn popover khi click ra ngoài (handled by autohide của Popover)
        // Không dùng focus.leave vì nó gây lỗi khi suggestions đang hiện
        
        // Đặt url_entry làm title widget của header bar
        // → URL entry nằm ở giữa, mở rộng chiếm không gian còn lại
        header_bar.set_title_widget(url_entry);

        // -----------------------------------------------------------------
        // TẠO NÚT NEW TAB
        // -----------------------------------------------------------------
        //
        var new_tab_button = new Button.from_icon_name("tab-new-symbolic");
        new_tab_button.tooltip_text = "New Tab";
        
        // CSS class "suggested-action": Button màu xanh (action chính)
        new_tab_button.add_css_class("suggested-action");
        
        // Connect signal "clicked"
        // Lambda: () => { ... } - hàm ẩn danh được gọi khi click
        new_tab_button.clicked.connect(() => {
            add_tab();  // Thêm tab mới trống
        });
        
        // Đặt ở bên phải header bar
        header_bar.pack_end(new_tab_button);

        // -----------------------------------------------------------------
        // TẠO NÚT HISTORY
        // -----------------------------------------------------------------
        //
        var history_button = new Button.from_icon_name("document-open-recent-symbolic");
        history_button.tooltip_text = "History";
        
        history_button.clicked.connect(() => {
            // Tạo và hiện HistoryDialog
            var dialog = new HistoryDialog(this);
            
            // Connect signal open_url từ dialog
            // Khi user chọn một mục lịch sử, mở URL trong tab mới
            dialog.open_url.connect((url) => {
                add_tab(url);
            });
            
            dialog.present();
        });
        
        header_bar.pack_end(history_button);

        // -----------------------------------------------------------------
        // TẠO TAB BAR VÀ TAB VIEW
        // -----------------------------------------------------------------
        //
        // TabView: Quản lý các pages (tabs)
        //   - Mỗi page có child widget (WebView)
        //   - Có title, icon, tooltip
        //
        // TabBar: UI để hiển thị và tương tác với tabs
        //   - Click để chọn tab
        //   - Kéo thả để đổi vị trí
        //   - Close button trên mỗi tab
        //
        tab_view = new Adw.TabView();
        tab_bar = new Adw.TabBar();
        tab_bar.set_view(tab_view);  // Kết nối TabBar với TabView
        
        toolbar_view.add_top_bar(tab_bar);      // TabBar dưới HeaderBar
        toolbar_view.set_content(tab_view);      // TabView là content chính

        // -----------------------------------------------------------------
        // KẾT NỐI SIGNALS
        // -----------------------------------------------------------------
        
        // URL Entry: Khi user nhấn Enter
        url_entry.activate.connect(on_url_activated);
        
        // Navigation buttons
        back_button.clicked.connect(() => {
            var web_view = get_current_web_view();
            if (web_view != null) web_view.go_back();
        });
        
        forward_button.clicked.connect(() => {
            var web_view = get_current_web_view();
            if (web_view != null) web_view.go_forward();
        });
        
        reload_button.clicked.connect(() => {
            var web_view = get_current_web_view();
            if (web_view != null) web_view.reload();
        });

        // -----------------------------------------------------------------
        // TAB VIEW SIGNALS
        // -----------------------------------------------------------------
        //
        // notify["selected-page"]: Khi tab được chọn thay đổi
        // Trong GObject, dùng notify::property-name để lắng nghe property changes
        //
        tab_view.notify["selected-page"].connect(on_selected_page_changed);
        
        // close_page: Khi user đóng một tab
        // Trả về true để confirm đóng
        tab_view.close_page.connect((view, page) => {
            tab_view.close_page_finish(page, true);  // Confirm đóng
            return true;
        });

        // -----------------------------------------------------------------
        // FIX: HYPRLAND WORKSPACE SWITCH FREEZE
        // -----------------------------------------------------------------
        //
        // Vấn đề: Khi chuyển workspace trong Hyprland, window bị freeze
        // Nguyên nhân: Window không nhận signal visibility change đúng cách
        // Giải pháp: Lắng nghe is-active signal và force refresh WebViews
        //
        // notify["is-active"]: Khi window được activate/deactivate
        // is-active: true khi window có focus, false khi không
        //
        this.notify["is-active"].connect(on_window_activation_changed);

        // -----------------------------------------------------------------
        // THÊM TAB MẶC ĐỊNH (DEFERRED)
        // -----------------------------------------------------------------
        //
        // Vấn đề: Tạo WebView trong constructor block window display
        // Giải pháp: Dùng GLib.Idle.add() để tạo tab sau khi window ready
        // 
        // GLib.Idle.add(): Thêm callback vào event loop
        // → Callback được gọi khi GTK event loop idle (sau khi window hiển thị)
        //
        message("Scheduling first tab creation...");
        GLib.Idle.add(() => {
            message("Idle callback: adding first tab now...");
            add_tab("https://www.google.com");
            message("First tab added");
            return false;  // false = chỉ chạy một lần, không lặp lại
        });
        
        message("Constructor finished - window ready to be presented");
    }

    // =========================================================================
    // HÀM THÊM TAB MỚI
    // =========================================================================
    //
    // Tham số:
    //   - uri: URL để load (mặc định = "" = tab trống)
    //
    private void add_tab(string uri = "") {
        // -----------------------------------------------------------------
        // TẠO WEBVIEW VỚI NETWORK SESSION
        // -----------------------------------------------------------------
        //
        // Object.new(): Cách tạo object với property được chỉ định
        // typeof(WebView): Kiểu class cần tạo
        // "network-session": Property name
        // get_network_session(): Giá trị property
        //
        // Tại sao dùng cách này thay vì new WebView()?
        //   → WebView không có constructor nhận NetworkSession
        //   → Phải dùng Object.new() với property
        //
        var web_view = (WebView) Object.new(typeof(WebView), "network-session", get_network_session());
        
        // -----------------------------------------------------------------
        // KẾT NỐI WEBVIEW SIGNALS
        // -----------------------------------------------------------------
        //
        // bind_property(): Tự động sync property giữa 2 objects
        //   Source: web_view.title
        //   Target: web_view.tooltip_text
        //   → Khi title thay đổi, tooltip_text tự động update
        //
        web_view.bind_property("title", web_view, "tooltip-text", BindingFlags.DEFAULT);
        
        // notify["uri"]: Khi URL thay đổi
        web_view.notify["uri"].connect(on_page_uri_changed);
        
        // load_changed: Khi trạng thái loading thay đổi
        web_view.load_changed.connect(on_load_changed);
        
        // -----------------------------------------------------------------
        // SECURITY: TLS Error Handling
        // -----------------------------------------------------------------
        //
        // load_failed_with_tls_errors: Khi gặp lỗi TLS/SSL
        // strict_tls: Reject tất cả các lỗi chứng chỉ để bảo mật
        //
        web_view.load_failed_with_tls_errors.connect((failing_uri, certificate, errors) => {
            critical("[Security] TLS Error for %s: %u", failing_uri, errors);
            
            // Hiển thị warning dialog
            var dialog = new Adw.AlertDialog(
                "Security Warning",
                "The security certificate for %s is not trusted. This site may not be secure.".printf(failing_uri)
            );
            dialog.add_response("cancel", "Go Back");
            dialog.add_response("continue", "Continue Anyway");
            dialog.set_response_appearance("continue", Adw.ResponseAppearance.DESTRUCTIVE);
            
            dialog.response.connect((response) => {
                if (response == "continue") {
                    // User chọn tiếp tục bất chấp rủi ro
                    message("User chose to continue despite TLS error");
                } else {
                    // Quay lại trang trước
                    web_view.go_back();
                }
            });
            
            dialog.present(this);
            
            // Return true để stop loading (cho phép user quyết định)
            return true;
        });
        
        // -----------------------------------------------------------------
        // THÊM WEBVIEW VÀO TABVIEW
        // -----------------------------------------------------------------
        //
        // append(): Thêm child và tạo TabPage mới
        // TabPage: Object đại diện cho một tab
        //
        var page = tab_view.append(web_view);
        page.title = "New Tab";
        page.icon = new ThemedIcon("applications-internet-symbolic");
        
        // Bind title của WebView với title của TabPage
        // → Tab title tự động update theo page title
        web_view.bind_property("title", page, "title", BindingFlags.DEFAULT);
        
        // Load URL nếu được cung cấp
        if (uri != "") {
            web_view.load_uri(uri);
        }
        
        // Chọn tab vừa tạo
        tab_view.set_selected_page(page);
        
        // Focus vào URL entry nếu tab trống
        if (uri == "") {
             url_entry.grab_focus();
        }

        // -----------------------------------------------------------------
        // SECURITY: Configure WebView Settings
        // -----------------------------------------------------------------
        //
        // DEVELOPER EXTRAS:
        //   - Chỉ enable trong DEBUG builds
        //   - Production: Tắt để ngăn user inspect/modify page content
        //
        // FILE ACCESS RESTRICTIONS:
        //   - Ngăn file:// URLs truy cập file khác
        //   - Ngăn universal access từ file URLs
        //
        var settings = web_view.get_settings();
        
        #if DEBUG
        settings.enable_developer_extras = true;
        message("Developer extras enabled (DEBUG build)");
        #else
        settings.enable_developer_extras = false;
        message("Developer extras disabled (RELEASE build)");
        #endif
        
        // Block dangerous file access
        settings.allow_file_access_from_file_urls = false;
        settings.allow_universal_access_from_file_urls = false;
        message("File access restrictions enabled");
        
        // -----------------------------------------------------------------
        // MEDIA & HARDWARE ACCELERATION SETTINGS
        // -----------------------------------------------------------------
        //
        // These settings are critical for smooth video playback
        // Without them, videos may fail to load or stutter
        //
        // HARDWARE ACCELERATION:
        //   - Uses GPU for rendering → smoother playback
        //   - Reduces CPU usage
        //
        // WEBGL:
        //   - Many video players use WebGL for rendering
        //   - Required for modern video streaming sites
        //
        // MEDIA CAPABILITIES:
        //   - Enables HTML5 video/audio playback
        //   - Supports various codecs and formats
        //
        // MEDIA STREAM:
        //   - Required for live streaming and WebRTC
        //   - Enables getUserMedia() for video conferencing sites
        //
        
        // Enable hardware acceleration for smooth video rendering
        settings.hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.ALWAYS;
        message("Hardware acceleration: ALWAYS");
        
        // Enable WebGL (required by many video players)
        settings.enable_webgl = true;
        message("WebGL enabled");
        
        // Enable media playback
        settings.enable_media = true;
        message("Media playback enabled");
        
        // Enable media capabilities API (for adaptive streaming)
        settings.enable_media_capabilities = true;
        message("Media capabilities enabled");
        
        // Enable media stream (for live video/WebRTC)
        settings.enable_media_stream = true;
        message("Media stream enabled");
        
        // Enable Web Audio API (for advanced audio processing)
        settings.enable_webaudio = true;
        message("Web Audio enabled");
        
        // Enable JavaScript (required for modern video players)
        settings.enable_javascript = true;
        
        // Enable JavaScript markup (for video player controls)
        settings.enable_javascript_markup = true;
        message("JavaScript features enabled for video players");
        
        // -----------------------------------------------------------------
        // PERFORMANCE OPTIMIZATION SETTINGS
        // -----------------------------------------------------------------
        //
        // These settings improve video decode/render performance
        //
        
        // Enable compositor (improves rendering performance)
        settings.enable_write_console_messages_to_stdout = false;  // Reduce overhead
        
        // Enable DNS prefetching for faster resource loading
        settings.enable_dns_prefetching = true;
        message("DNS prefetching enabled");
        
        // Enable page caching
        settings.enable_page_cache = true;
        message("Page cache enabled");
        
        // Enable smooth scrolling (uses GPU compositing)
        settings.enable_smooth_scrolling = true;
        message("Smooth scrolling enabled");
        
        // Enable site-specific quirks for better compatibility
        settings.enable_site_specific_quirks = true;
        message("Site-specific quirks enabled");
        
        
        
        
        
        // -----------------------------------------------------------------
        // INJECT CONSOLE LOGGING SCRIPT
        // -----------------------------------------------------------------
        //
        // WebKit 6 không có console_message signal
        // Workaround: Override console.log trong JavaScript
        //             và forward qua message handler
        //
        var content_manager = web_view.get_user_content_manager();
        
        // Đăng ký message handler cho logging
        content_manager.register_script_message_handler("logger", "");
        
        // Script override console methods
        // Mỗi khi JS gọi console.log(), tin nhắn được gửi đến Vala
        string log_script = """
            var oldLog = console.log;
            var oldWarn = console.warn;
            var oldError = console.error;
            
            console.log = function(message) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                    window.webkit.messageHandlers.logger.postMessage("LOG: " + message);
                }
                oldLog.apply(console, arguments);
            };
            
            console.warn = function(message) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                    window.webkit.messageHandlers.logger.postMessage("WARN: " + message);
                }
                oldWarn.apply(console, arguments);
            };
            
            console.error = function(message) {
                if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.logger) {
                    window.webkit.messageHandlers.logger.postMessage("ERROR: " + message);
                }
                oldError.apply(console, arguments);
            };
            
            window.onerror = function(message, source, lineno, colno, error) {
                console.error(message + " at " + source + ":" + lineno);
            };
        """;
        
        // UserScript: Script được inject vào trang web
        // Tham số:
        //   1. source: Nội dung script
        //   2. injected_frames: TOP_FRAME = chỉ main frame, không inject vào iframes
        //   3. injection_time: START = inject ngay khi document được tạo
        //   4. allow_list: null = inject vào mọi URL
        //   5. block_list: null = không block URL nào
        //
        var logger_script = new UserScript(
            log_script,
            UserContentInjectedFrames.TOP_FRAME,
            UserScriptInjectionTime.START,
            null, null
        );
        content_manager.add_script(logger_script);
        
        // -----------------------------------------------------------------
        // INJECT AUTOFILL SCRIPT
        // -----------------------------------------------------------------
        //
        // Load autofill.js từ file và inject vào trang
        //
        try {
            string js_content = "";
            
            // Các đường dẫn có thể có autofill.js
            var install_path = Path.build_filename("/usr/local/share/my-browser/autofill.js");
            var local_path = Path.build_filename(Environment.get_current_dir(), "app", "autofill.js");
            
            message("Looking for autofill script at: %s", local_path);
            
            // Thử load từ local path trước (development)
            if (FileUtils.test(local_path, FileTest.EXISTS)) {
                FileUtils.get_contents(local_path, out js_content);
                message("Found autofill.js at local path");
            }
            // Fallback về install path (production)
            else if (FileUtils.test(install_path, FileTest.EXISTS)) {
                FileUtils.get_contents(install_path, out js_content);
                message("Found autofill.js at install path");
            } else {
                warning("autofill.js not found!");
            }
            
            if (js_content != "") {
                // Inject autofill script
                // END = inject sau khi DOM ready
                var script = new UserScript(
                    js_content,
                    UserContentInjectedFrames.TOP_FRAME,
                    UserScriptInjectionTime.END,
                    null, null
                );
                content_manager.add_script(script);
            }
        } catch (Error e) {
            warning("Failed to load autofill script: %s", e.message);
        }

        // -----------------------------------------------------------------
        // ĐĂNG KÝ PASSWORD MANAGER MESSAGE HANDLER
        // -----------------------------------------------------------------
        //
        // Cho phép JavaScript gửi tin nhắn qua:
        //   webkit.messageHandlers.password_manager.postMessage(...)
        //
        content_manager.register_script_message_handler("password_manager", "");
        
        // -----------------------------------------------------------------
        // KẾT NỐI CALLBACKS CHO MESSAGE HANDLERS
        // -----------------------------------------------------------------
        //
        // Signal.connect(): Cách thấp cấp để connect signal
        // Cần dùng vì signal có "detail" (::logger, ::password_manager)
        //
        // "script-message-received::logger": Signal name với detail
        // (Callback) on_logger_message: Ép kiểu hàm thành Callback
        // this: User data được truyền vào callback
        //
        Signal.connect(content_manager, "script-message-received::logger", (Callback) on_logger_message, this);
        Signal.connect(content_manager, "script-message-received::password_manager", (Callback) on_password_message, this);
    }
    
    // =========================================================================
    // CALLBACK: XỬ LÝ LOG TỪ JAVASCRIPT
    // =========================================================================
    //
    // static: Hàm không cần instance, có thể gọi trực tiếp
    // Tham số:
    //   - manager: UserContentManager phát signal
    //   - result: Giá trị từ JavaScript (JSC.Value)
    //   - self: BrowserWindow instance (truyền qua user_data)
    //
    private static void on_logger_message(UserContentManager manager, JSC.Value result, BrowserWindow self) {
        message("Logger message received!");
        if (result.is_string()) {
            string msg = result.to_string();
            print("JS_CONSOLE: %s\n", msg);  // In ra terminal
        }
    }
    
    // =========================================================================
    // CALLBACK: XỪL LÝ TIN NHẮN TỪ PASSWORD MANAGER (JAVASCRIPT)
    // =========================================================================
    //
    // Đây là hàm quan trọng nhất - cầu nối giữa JavaScript và Vala
    //
    // SECURITY: Enhanced validation to prevent malicious message injection
    //
    private static void on_password_message(UserContentManager manager, JSC.Value result, BrowserWindow self) {
        message("Password manager message received!");
        
        try {
            if (result.is_string()) {
                // Chuyển JSC.Value thành Vala string
                string msg = result.to_string();
                
                // -----------------------------------------------------------------
                // SECURITY: Validate message length
                // -----------------------------------------------------------------
                if (msg.length > 10000) {
                    warning("Message too large (%zu bytes), rejecting", msg.length);
                    return;
                }
                
                message("Received message: %s", msg);
                
                // -----------------------------------------------------------------
                // PARSE JSON TỪ JAVASCRIPT
                // -----------------------------------------------------------------
                //
                // Json.Parser: Đọc JSON string thành object
                //
                var parser = new Json.Parser();
                parser.load_from_data(msg);
                var root = parser.get_root().get_object();
                
                // -----------------------------------------------------------------
                // SECURITY: Validate JSON schema
                // -----------------------------------------------------------------
                if (!root.has_member("action")) {
                    warning("Missing 'action' field in message");
                    return;
                }
                
                var action = root.get_string_member("action");
                
                // -----------------------------------------------------------------
                // SECURITY: Action whitelist
                // -----------------------------------------------------------------
                if (action != "save_password" && action != "request_credentials" && action != "fill_credential") {
                    warning("Invalid action: %s", action);
                    return;
                }
                
                message("Action: %s", action);
                
                // ---------------------------------------------------------
                // ACTION 1: SAVE_PASSWORD
                // ---------------------------------------------------------
                //
                // Khi JavaScript phát hiện user vừa đăng nhập
                // và gửi yêu cầu lưu mật khẩu
                //
                if (action == "save_password") {
                    // Validate required fields
                    if (!root.has_member("username") || 
                        !root.has_member("password") || 
                        !root.has_member("url")) {
                        warning("save_password: Missing required fields");
                        return;
                    }
                    
                    // Lấy thông tin từ JSON
                    string username = root.get_string_member("username");
                    string password = root.get_string_member("password");
                    string url = root.get_string_member("url");
                    
                    // SECURITY: Validate field lengths
                    if (username.length > 255 || password.length > 1024 || url.length > 2048) {
                        warning("save_password: Field length validation failed");
                        return;
                    }
                    
                    // Chuẩn hóa URL thành origin
                    // https://facebook.com/login?ref=abc → https://facebook.com
                    string origin = self.get_origin(url);
                    
                    // Kiểm tra credential đã tồn tại chưa
                    if (CredentialManager.get_default().has_credential(origin, username)) {
                        message("Credential already exists for %s, skipping save dialog", username);
                        return;  // Không cần lưu lại
                    }
                    
                    message("Save password request - User: %s, URL: %s", username, url);
                    
                    // -------------------------------------------------
                    // HIỂN THỊ DIALOG "LƯU MẬT KHẨU?"
                    // -------------------------------------------------
                    //
                    // Adw.AlertDialog: Modern replacement for MessageDialog
                    var dlg = new Adw.AlertDialog(
                        "Save Password?",                         // Heading
                        "Do you want to save the password for %s?".printf(username)  // Body
                    );
                    
                    // Thêm các responses (buttons)
                    dlg.add_response("no", "No");
                    dlg.add_response("yes", "Yes");
                    
                    // Xử lý khi user chọn
                    dlg.response.connect((response) => {
                        if (response == "yes") {
                            // Lưu credential vào Keyring
                            CredentialManager.get_default().save_credential(origin, username, password);
                        }
                    });
                    
                    dlg.present(self);
                }
                
                // ---------------------------------------------------------
                // ACTION 2: REQUEST_CREDENTIALS
                // ---------------------------------------------------------
                //
                // Khi user focus vào ô username/password
                // JavaScript yêu cầu credentials đã lưu
                //
                else if (action == "request_credentials") {
                    // Validate required fields
                    if (!root.has_member("url")) {
                        warning("request_credentials: Missing url field");
                        return;
                    }
                    
                    string url = root.get_string_member("url");
                    
                    // SECURITY: Validate URL length
                    if (url.length > 2048) {
                        warning("request_credentials: URL too long");
                        return;
                    }
                    
                    string origin = self.get_origin(url);
                    
                    message("Request credentials for: %s", origin);
                    
                    // Tìm credential trong Keyring
                    var cred = CredentialManager.get_default().get_credential_sync(origin);
                    
                    if (cred != null) {
                        message("Found credential for %s", cred.username);
                        
                        var web_view = self.get_current_web_view();
                        if (web_view != null) {
                            // Gọi JavaScript function để hiện popup
                            // evaluate_javascript.begin(): Gọi async (không chờ kết quả)
                            string js = "if(window.showCredentialPopup) window.showCredentialPopup('%s');".printf(cred.username);
                            web_view.evaluate_javascript.begin(js, -1, null, null, null, null);
                        }
                    } else {
                        message("No credentials found for %s", origin);
                    }
                }
                
                // ---------------------------------------------------------
                // ACTION 3: FILL_CREDENTIAL
                // ---------------------------------------------------------
                //
                // Khi user chọn credential từ popup
                // JavaScript yêu cầu điền username/password
                //
                else if (action == "fill_credential") {
                    // Validate required fields
                    if (!root.has_member("url") || !root.has_member("username")) {
                        warning("fill_credential: Missing required fields");
                        return;
                    }
                    
                    string url = root.get_string_member("url");
                    string username = root.get_string_member("username");
                    
                    // SECURITY: Validate field lengths
                    if (url.length > 2048 || username.length > 255) {
                        warning("fill_credential: Field length validation failed");
                        return;
                    }
                    
                    string origin = self.get_origin(url);
                    
                    message("Fill credential request for: %s", username);
                    
                    // Lấy credential từ Keyring
                    var cred = CredentialManager.get_default().get_credential_sync(origin);
                    
                    if (cred != null && cred.username == username) {
                        var web_view = self.get_current_web_view();
                        if (web_view != null) {
                            // -------------------------------------------------
                            // SECURITY: Use JSON encoding instead of manual escaping
                            // -------------------------------------------------
                            //
                            // Manual escaping is incomplete and error-prone
                            // JSON.to_string() handles all special characters properly
                            //
                            var builder = new Json.Builder();
                            builder.begin_object();
                            builder.set_member_name("u");
                            builder.add_string_value(cred.username);
                            builder.set_member_name("p");
                            builder.add_string_value(cred.password);
                            builder.end_object();
                            
                            var generator = new Json.Generator();
                            generator.set_root(builder.get_root());
                            string json_data = generator.to_data(null);
                            
                            // Generate one-time security token
                            string token = ("%" + int64.FORMAT + "_%d").printf(GLib.get_real_time(), GLib.Random.int_range(1000, 9999));
                            
                            // Set token first, then call fill with token verification
                            string set_token_js = "window._setAutofillToken('%s');".printf(token);
                            string fill_js = "(function() { var d = %s; window.fillCredentialsSecure(d.u, d.p, '%s'); })();".printf(json_data, token);
                            
                            // Execute both in sequence
                            web_view.evaluate_javascript.begin(set_token_js + fill_js, -1, null, null, null, null);
                            
                            message("Credentials filled securely for %s", username);
                        }
                    }
                }
            }
        } catch (Error e) {
            warning("Error handling password message: %s", e.message);
        }
    }
    
    // =========================================================================
    // CALLBACK: KHI TRANG WEB LOAD XONG
    // =========================================================================
    //
    // Tham số:
    //   - load_event: Trạng thái loading hiện tại
    //     - STARTED: Bắt đầu load
    //     - REDIRECTED: Có redirect
    //     - COMMITTED: Server response received
    //     - FINISHED: Load hoàn tất
    //
    private void on_load_changed(WebKit.LoadEvent load_event) {
        if (load_event == WebKit.LoadEvent.FINISHED) {
             var web_view = get_current_web_view();
             if (web_view != null && web_view.uri != null) {
                  // Thêm vào lịch sử
                  // title ?? uri: Dùng title nếu có, nếu không dùng uri
                  HistoryManager.get_default().add(web_view.uri, web_view.title ?? web_view.uri);
             }
        }
    }

    // =========================================================================
    // HÀM CHUẨN HÓA URL THÀNH ORIGIN
    // =========================================================================
    //
    // Input:  "https://www.facebook.com/login.php?ref=xyz"
    // Output: "https://www.facebook.com"
    //
    // Tại sao cần origin?
    //   - Lưu credential theo origin, không theo full URL
    //   - https://facebook.com/login và https://facebook.com/home
    //     → Cùng dùng chung một credential
    //
    private string get_origin(string url) {
        try {
            // Uri.parse(): Parse URL string thành Uri object
            var uri = Uri.parse(url, UriFlags.NONE);
            
            // get_scheme(): "https"
            // get_host(): "www.facebook.com"
            return "%s://%s".printf(uri.get_scheme(), uri.get_host());
        } catch (Error e) {
            return url;  // Fallback nếu parse thất bại
        }
    }

    // =========================================================================
    // HÀM LẤY WEBVIEW HIỆN TẠI
    // =========================================================================
    //
    // Trả về WebView của tab đang được chọn
    // null nếu không có tab nào
    //
    private WebView? get_current_web_view() {
        var page = tab_view.selected_page;
        if (page != null) {
            // page.child là widget trong tab
            // Cast về WebView
            return (WebView) page.child;
        }
        return null;
    }

    // =========================================================================
    // CALLBACK: KHI TAB ĐƯỢC CHỌN THAY ĐỔI
    // =========================================================================
    //
    // Cập nhật URL entry và navigation buttons khi chuyển tab
    //
    private void on_selected_page_changed() {
        var web_view = get_current_web_view();
        if (web_view != null) {
            // Cập nhật URL entry
            url_entry.text = web_view.uri ?? "";
            
            // Cập nhật trạng thái navigation buttons
            update_nav_buttons(web_view);
        } else {
            url_entry.text = "";
        }
    }

    // =========================================================================
    // CALLBACK: KHI URL CỦA TRANG THAY ĐỔI
    // =========================================================================
    //
    // Được gọi khi navigate trong cùng một tab
    //
    private void on_page_uri_changed(Object object, ParamSpec pspec) {
         var web_view = (WebView) object;
         
         // Chỉ update nếu đây là tab đang được chọn
         if (web_view == get_current_web_view()) {
             url_entry.text = web_view.uri ?? "";
             update_nav_buttons(web_view);
         }
    }
    
    // =========================================================================
    // CẬP NHẬT TRẠNG THÁI NAVIGATION BUTTONS
    // =========================================================================
    //
    // Enable/disable buttons dựa trên history của WebView
    //
    private void update_nav_buttons(WebView web_view) {
        // can_go_back(): true nếu có lịch sử để quay lại
        // can_go_forward(): true nếu đã go_back và có thể go_forward
        //
        // sensitive: Trạng thái enable/disable của widget
        //   true = clickable, false = grayed out
        //
        back_button.sensitive = web_view.can_go_back();
        forward_button.sensitive = web_view.can_go_forward();
    }

    // =========================================================================
    // CẬP NHẬT GỢI Ý URL TỪ LỊCH SỬ
    // =========================================================================
    //
    // Được gọi mỗi khi text trong url_entry thay đổi
    // Tìm kiếm trong lịch sử và cập nhật ListStore
    //
    private void update_url_completions() {
        // Xóa tất cả gợi ý cũ
        Widget? child = completion_list.get_first_child();
        while (child != null) {
            Widget? next = child.get_next_sibling();
            completion_list.remove(child);
            child = next;
        }
        
        // Lấy text hiện tại trong entry
        string query = url_entry.text.strip().down();  // Lowercase for matching
        
        // Nếu query quá ngắn hoặc là full URL, không hiển thị gợi ý
        if (query.length < 1 || query.has_prefix("http://") || query.has_prefix("https://")) {
            completion_popover.popdown();
            return;
        }
        
        // -----------------------------------------------------------------
        // POPULAR DOMAINS (Chrome-style suggestions)
        // -----------------------------------------------------------------
        string[] popular_domains = {
            "google.com",
            "facebook.com",
            "youtube.com",
            "twitter.com",
            "github.com",
            "reddit.com",
            "amazon.com",
            "wikipedia.org",
            "stackoverflow.com",
            "linkedin.com"
        };
        
        var seen_urls = new Gee.HashSet<string>();
        HistoryItem[] suggestions = {};
        
        // -----------------------------------------------------------------
        // 1. POPULAR DOMAIN MATCHING (thêm trước)
        // -----------------------------------------------------------------
        foreach (string domain in popular_domains) {
            if (domain.has_prefix(query) || domain.contains(query)) {
                string url = "https://" + domain;
                if (!seen_urls.contains(url)) {
                    // Get simple title from domain (e.g., "google" from "google.com")
                    string title = domain.split(".")[0];
                    title = title.substring(0, 1).up() + title.substring(1);  // Capitalize
                    
                    HistoryItem item = { url, title, "" };  // Empty timestamp for suggestions
                    suggestions += item;
                    seen_urls.add(url);
                    
                    if (suggestions.length >= 5) break;  // Max 5 popular suggestions
                }
            }
        }
        
        // -----------------------------------------------------------------
        // 2. HISTORY SEARCH (thêm sau)
        // -----------------------------------------------------------------
        var results = HistoryManager.get_default().search(query);
        
        foreach (var item in results) {
            if (!seen_urls.contains(item.url)) {
                seen_urls.add(item.url);
                suggestions += item;
                
                // Giới hạn tổng cộng 10 suggestions
                if (suggestions.length >= 10) {
                    break;
                }
            }
        }
        
        // Nếu không có gợi ý nào, ẩn popover
        if (suggestions.length == 0) {
            completion_popover.popdown();
            return;
        }
        
        // -----------------------------------------------------------------
        // THÊM KẾT QUẢ VÀO LISTBOX
        // -----------------------------------------------------------------
        for (int i = 0; i < suggestions.length; i++) {
            var item = suggestions[i];
            
            var row = new Adw.ActionRow();
            
            // Title with visit count (Chrome-style)
            string title_text = item.title != "" ? item.title : item.url;
            if (item.visit_count > 1) {
                // Show visit count for frequently visited pages
                row.title = GLib.Markup.escape_text(title_text) + 
                           " <span size='small' foreground='#888'>(%d×)</span>".printf(item.visit_count);
            } else {
                row.title = GLib.Markup.escape_text(title_text);
            }
            
            row.subtitle = GLib.Markup.escape_text(item.url);
            row.activatable = true;
            
            completion_list.append(row);
        }
        
        completion_popover.popup();
    }

    // =========================================================================
    // FIX: REFRESH WEBVIEWS KHI WINDOW ĐƯỢC ACTIVATE
    // =========================================================================
    //
    // Được gọi khi window được activate/deactivate (chuyển workspace, minimize, etc.)
    // Fix cho bug: WebView bị freeze khi chuyển workspace trong Hyprland
    //
    // Giải thích kỹ thuật:
    //   - Wayland compositors như Hyprland không gửi visibility signals giống GNOME
    //   - WebView không tự động refresh render khi window được activate lại
    //   - NUCLEAR OPTION: Thực sự thay đổi size để trigger resize event
    //     → Giống như minimize/maximize làm
    //
    private void on_window_activation_changed() {
        // Chỉ xử lý khi window được activate (is-active = true)
        if (!this.is_active) {
            return;
        }
        
        message("Window activated - forcing REAL WebView resize");
        
        // -----------------------------------------------------------------
        // NUCLEAR OPTION: FORCE REAL SIZE CHANGE
        // -----------------------------------------------------------------
        //
        // Tại sao visibility toggle không đủ?
        //   - WebView internal state không reset
        //   - Render pipeline không được trigger
        //
        // Tại sao minimize work?
        //   - Nó thực sự thay đổi size allocation
        //   - Trigger size-allocate signal thật sự
        //
        // Giải pháp: Fake minimize bằng cách thay đổi size thật sự
        //
        int n_pages = tab_view.get_n_pages();
        
        // Step 1: Lưu current sizes và set temporary size
        for (int i = 0; i < n_pages; i++) {
            var page = tab_view.get_nth_page(i);
            if (page != null) {
                var web_view = page.child as WebView;
                if (web_view != null) {
                    // Force set size nhỏ
                    // Điều này trigger size-allocate với size mới
                    web_view.set_size_request(1, 1);
                }
            }
        }
        
        // Step 2: Delay nhỏ để GTK process resize
        Timeout.add(10, () => {
            // Restore normal size
            for (int i = 0; i < n_pages; i++) {
                var page = tab_view.get_nth_page(i);
                if (page != null) {
                    var web_view = page.child as WebView;
                    if (web_view != null) {
                        // Reset về -1 = no size constraint
                        // WebView sẽ expand về full size
                        web_view.set_size_request(-1, -1);
                        
                        // Sau khi reset size, force draw
                        web_view.queue_resize();
                        web_view.queue_draw();
                    }
                }
            }
            
            message("WebView resize cycle complete");
            return false;
        });
    }

    // =========================================================================
    // CALLBACK: KHI USER NHẤN ENTER TRONG URL ENTRY
    // =========================================================================
    //
    private void on_url_activated() {
        // Lấy text và xóa khoảng trắng đầu/cuối
        var url = url_entry.text.strip();
        if (url == "") return;

        // -----------------------------------------------------------------
        // XÁC ĐỊNH CÓ PHẢI URL HAY SEARCH QUERY
        // -----------------------------------------------------------------
        //
        // Heuristic đơn giản:
        //   - Có "://" → URL (http://, https://, file://)
        //   - Bắt đầu bằng "about:" hoặc "file:" → URL
        //   - Có khoảng trắng → Search query
        //   - Không có dấu chấm → Search query
        //   - Còn lại → Có thể là domain (google.com)
        //
        bool is_url = url.contains("://") || url.has_prefix("about:") || url.has_prefix("file:");
        
        if (!is_url) {
            if (url.contains(" ") || !url.contains(".")) {
                // Có khoảng trắng hoặc không có dấu chấm → Search
                // Uri.escape_string(): Encode ký tự đặc biệt cho URL
                //   "hello world" → "hello%20world"
                url = "https://www.google.com/search?q=" + Uri.escape_string(url, null, true);
            } else {
                // Có thể là domain → Thêm https://
                url = "https://" + url;
            }
        }
        
        // Load URL vào tab hiện tại
        var web_view = get_current_web_view();
        if (web_view != null) {
            web_view.load_uri(url);
        } else {
            // Không có tab → Tạo tab mới
            add_tab(url);
        }
    }
}

// =============================================================================
// 📝 TÓM TẮT LUỒNG HOẠT ĐỘNG
// =============================================================================
//
// 1. BrowserApp.activate() gọi new BrowserWindow(this)
//
// 2. Constructor BrowserWindow:
//    a) Tạo layout (ToolbarView, HeaderBar, TabBar, TabView)
//    b) Tạo widgets (buttons, url_entry)
//    c) Connect signals
//    d) add_tab("https://www.google.com")
//
// 3. add_tab():
//    a) Tạo WebView với NetworkSession (cookies persistent)
//    b) Inject logger script (forward console.log)
//    c) Inject autofill.js (password management)
//    d) Đăng ký message handlers
//    e) Thêm WebView vào TabView
//
// 4. Khi user browse:
//    a) on_load_changed() → Thêm vào history
//    b) on_page_uri_changed() → Update URL entry
//    c) Autofill.js detect login → on_password_message()
//
// 5. Khi user đăng nhập:
//    a) autofill.js phát hiện và gửi save_password
//    b) on_password_message() nhận và hiện dialog
//    c) User confirm → CredentialManager.save_credential()
//
// 6. Khi user focus vào form đăng nhập:
//    a) autofill.js gửi request_credentials
//    b) on_password_message() tìm trong Keyring
//    c) Nếu có → Gọi showCredentialPopup()
//    d) User chọn → fillCredentials() điền vào form
//
// =============================================================================
