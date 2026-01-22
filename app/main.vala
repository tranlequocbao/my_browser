// =============================================================================
// FILE: main.vala - ĐIỂM VÀO (ENTRY POINT) CỦA ỨNG DỤNG
// =============================================================================
//
// 📚 KIẾN THỨC NỀN TẢNG:
// -----------------------
// 1. VALA là gì?
//    - Vala là ngôn ngữ lập trình hiện đại, cú pháp giống C# và Java
//    - Biên dịch ra mã C, chạy rất nhanh như ứng dụng C thông thường
//    - Được thiết kế đặc biệt để xây dựng ứng dụng GNOME/GTK
//
// 2. GTK là gì?
//    - GTK (GIMP ToolKit) là thư viện đồ họa để tạo giao diện người dùng
//    - Có các widget như: Button, Entry, Label, Window...
//
// 3. Adwaita là gì?
//    - Adwaita (libadwaita) là thư viện mở rộng của GTK
//    - Cung cấp các widget hiện đại hơn: HeaderBar, TabView, MessageDialog...
//    - Tuân theo thiết kế GNOME Human Interface Guidelines
//
// =============================================================================

// -----------------------------------------------------------------------------
// PHẦN 1: IMPORT THƯ VIỆN (Using Statements)
// -----------------------------------------------------------------------------
// Giống như #include trong C hoặc import trong Python
// Khai báo các thư viện cần dùng trong file này

using Gtk;    // Thư viện đồ họa cơ bản (buttons, entries, windows...)
using Adw;    // Thư viện Adwaita (giao diện GNOME hiện đại)

// -----------------------------------------------------------------------------
// PHẦN 2: ĐỊNH NGHĨA LỚP ỨNG DỤNG CHÍNH (Application Class)
// -----------------------------------------------------------------------------
// 
// Trong GTK, mọi ứng dụng đều bắt đầu từ một Application object
// Nó quản lý vòng đời ứng dụng: khởi động → chạy → thoát
//
// Cấu trúc thừa kế:
//   GLib.Object  →  GLib.Application  →  Gtk.Application  →  Adw.Application
//                                                               ↑
//                                                          BrowserApp
//
// Tại sao dùng Adw.Application thay vì Gtk.Application?
// → Adw.Application tự động thiết lập theme Adwaita và các styles GNOME
//

public class BrowserApp : Adw.Application {
    // =========================================================================
    // CONSTRUCTOR - Hàm khởi tạo đối tượng
    // =========================================================================
    //
    // Được gọi khi tạo: new BrowserApp()
    // Object(...): Cú pháp Vala để khởi tạo object với các thuộc tính
    //
    public BrowserApp() {
        Object(
            // application_id: Định danh duy nhất cho ứng dụng
            // Format: tên miền ngược (reverse domain notation)
            // VD: com.example.MyBrowser → thuộc về example.com
            // Điều này giúp tránh xung đột tên giữa các ứng dụng
            application_id: "com.example.MyBrowser",
            
            // flags: Các cờ cấu hình ứng dụng
            // NON_UNIQUE: Cho phép nhiều instance, không yêu cầu D-Bus registration
            // Điều này giúp tránh lỗi "Failed to register" trên một số hệ thống
            flags: ApplicationFlags.NON_UNIQUE
        );
    }

    // =========================================================================
    // VÒNG ĐỜI ỨNG DỤNG (Application Lifecycle)
    // =========================================================================
    //
    // ┌─────────────────────────────────────────────────────────────────┐
    // │                     VÒNG ĐỜI ỨNG DỤNG GTK                       │
    // ├─────────────────────────────────────────────────────────────────┤
    // │                                                                 │
    // │   run()  →  startup()  →  activate()  →  [Ứng dụng chạy]       │
    // │                                               │                 │
    // │                                               ▼                 │
    // │                                          shutdown()             │
    // │                                                                 │
    // └─────────────────────────────────────────────────────────────────┘
    //
    // - startup():  Khởi tạo một lần khi ứng dụng bắt đầu
    // - activate(): Mỗi khi cần hiển thị cửa sổ (mở app, click icon dock...)
    // - shutdown(): Dọn dẹp trước khi thoát
    //
    
    // -------------------------------------------------------------------------
    // STARTUP - Khởi tạo ứng dụng (chạy một lần duy nhất)
    // -------------------------------------------------------------------------
    //
    // "protected override": 
    //   - protected: Chỉ class này và class con có thể gọi
    //   - override: Ghi đè phương thức từ class cha (Adw.Application)
    //
    protected override void startup() {
        // Gọi startup() của class cha trước
        // QUAN TRỌNG: Luôn gọi base.method() khi override để đảm bảo
        // các thiết lập cần thiết của thư viện được thực hiện
        base.startup();
        
        // -----------------------------------------------------------------
        // CẤU HÌNH CHẾ ĐỘ MÀU (Color Scheme Configuration)
        // -----------------------------------------------------------------
        //
        // StyleManager: Quản lý theme và màu sắc cho toàn ứng dụng
        // get_default(): Lấy instance duy nhất (Singleton pattern)
        //
        var style_manager = Adw.StyleManager.get_default();
        
        // ColorScheme options:
        //   - DEFAULT:          Theo cài đặt hệ thống (sáng/tối tự động)
        //   - FORCE_LIGHT:      Luôn dùng theme sáng
        //   - FORCE_DARK:       Luôn dùng theme tối
        //   - PREFER_LIGHT:     Ưu tiên sáng, nhưng cho phép dark
        //   - PREFER_DARK:      Ưu tiên tối, nhưng cho phép light
        //
        style_manager.color_scheme = Adw.ColorScheme.DEFAULT;
    }

    // -------------------------------------------------------------------------
    // ACTIVATE - Kích hoạt ứng dụng (tạo và hiển thị cửa sổ)
    // -------------------------------------------------------------------------
    //
    // Được gọi khi:
    //   - Người dùng mở ứng dụng lần đầu
    //   - Người dùng click vào icon ứng dụng khi đã mở (raise window)
    //   - Ứng dụng được kích hoạt từ D-Bus
    //
    protected override void activate() {
        message("main.vala: activate() called - creating window");
        
        // Tạo cửa sổ trình duyệt mới
        // 'this' là tham chiếu đến BrowserApp hiện tại
        // Cửa sổ cần biết nó thuộc về Application nào
        var window = new BrowserWindow(this);
        
        message("main.vala: BrowserWindow created");
        message("main.vala: Window application is: %s", (window.application != null).to_string());
        
        // present(): Hiển thị cửa sổ và đưa lên foreground
        // Khác với show() - present() còn đảm bảo cửa sổ được focus
        message("main.vala: About to call present()...");
        window.present();
        message("main.vala: present() returned!");
        
        message("main.vala: Window visible: %s", window.get_visible().to_string());
        message("main.vala: Window is-active: %s", window.is_active.to_string());
        message("main.vala: activate() finished");
    }

    // =========================================================================
    // HÀM MAIN - ĐIỂM VÀO CỦA CHƯƠNG TRÌNH
    // =========================================================================
    //
    // Đây là hàm đầu tiên được gọi khi chạy chương trình
    // Tương tự như main() trong C hoặc if __name__ == "__main__" trong Python
    //
    // Tham số:
    //   - args: Mảng các tham số từ command line
    //           VD: ./my-browser --help → args = ["./my-browser", "--help"]
    //
    // Giá trị trả về:
    //   - int: Mã thoát (0 = thành công, khác 0 = có lỗi)
    //
    public static int main(string[] args) {
        // Tạo instance ứng dụng và chạy nó
        // run(args): Bắt đầu vòng lặp GTK và xử lý sự kiện
        // Hàm này block cho đến khi ứng dụng thoát
        return new BrowserApp().run(args);
    }
}

// =============================================================================
// 📝 TÓM TẮT LUỒNG CHẠY CỦA ỨNG DỤNG
// =============================================================================
//
// 1. Terminal chạy: ./my-browser
//
// 2. Hệ thống gọi main(args)
//
// 3. main() tạo BrowserApp và gọi run()
//
// 4. run() kích hoạt chuỗi sự kiện:
//    a) startup() → Thiết lập theme
//    b) activate() → Tạo BrowserWindow và hiển thị
//
// 5. Ứng dụng đợi input từ người dùng (event loop)
//
// 6. Khi người dùng đóng cửa sổ cuối cùng:
//    a) shutdown() được gọi
//    b) run() trả về mã thoát
//    c) main() trả về mã đó cho hệ thống
//
// =============================================================================
