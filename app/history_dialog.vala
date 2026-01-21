// =============================================================================
// FILE: history_dialog.vala - HỘP THOẠI HIỂN THỊ LỊCH SỬ DUYỆT WEB
// =============================================================================
//
// 📚 KIẾN THỨC NỀN TẢNG:
// -----------------------
// 1. MODAL DIALOG là gì?
//    - Cửa sổ "phụ" xuất hiện trên cửa sổ chính
//    - "Modal" = người dùng phải tương tác với dialog trước khi quay lại cửa sổ chính
//    - VD: Hộp thoại "Save As", "Confirm Delete", "History"...
//
// 2. SIGNAL là gì?
//    - Cơ chế thông báo sự kiện trong GTK
//    - Widget A "emit" signal, Widget B "connect" để lắng nghe
//    - Pattern Observer: Publisher-Subscriber
//
// 3. LISTBOX là gì?
//    - Container chứa danh sách các hàng (rows)
//    - Mỗi hàng có thể click được
//    - Giống ListView trong các framework khác
//
// =============================================================================
//
// 📊 SƠ ĐỒ CẤU TRÚC GIAO DIỆN:
//
// ┌─────────────────────────────────────────────────────────────────────┐
// │ HistoryDialog (Adw.Window)                                         │
// │ ┌─────────────────────────────────────────────────────────────────┐│
// │ │ ToolbarView                                                     ││
// │ │ ┌─────────────────────────────────────────────────────────────┐││
// │ │ │ HeaderBar                                      [Clear]      │││
// │ │ ├─────────────────────────────────────────────────────────────┤││
// │ │ │ ScrolledWindow                                              │││
// │ │ │ ┌─────────────────────────────────────────────────────────┐│││
// │ │ │ │ Box                                                     ││││
// │ │ │ │ ┌─────────────────────────────────────────────────────┐││││
// │ │ │ │ │ ListBox                                             │││││
// │ │ │ │ │ ┌─────────────────────────────────────────────────┐│││││
// │ │ │ │ │ │ ActionRow: "Google"                             ││││││
// │ │ │ │ │ │           https://www.google.com                ││││││
// │ │ │ │ │ ├─────────────────────────────────────────────────┤│││││
// │ │ │ │ │ │ ActionRow: "Facebook"                           ││││││
// │ │ │ │ │ │           https://www.facebook.com              ││││││
// │ │ │ │ │ └─────────────────────────────────────────────────┘│││││
// │ │ │ │ └─────────────────────────────────────────────────────┘││││
// │ │ │ └─────────────────────────────────────────────────────────┘│││
// │ │ └─────────────────────────────────────────────────────────────┘││
// │ └─────────────────────────────────────────────────────────────────┘│
// └─────────────────────────────────────────────────────────────────────┘
//
// =============================================================================

// -----------------------------------------------------------------------------
// PHẦN 1: IMPORT THƯ VIỆN
// -----------------------------------------------------------------------------

using Gtk;    // Thư viện đồ họa cơ bản (Button, Box, ListBox...)
using Adw;    // Thư viện Adwaita (Window, HeaderBar, ActionRow...)

// -----------------------------------------------------------------------------
// PHẦN 2: CLASS HISTORYDIALOG - Định nghĩa hộp thoại lịch sử
// -----------------------------------------------------------------------------
//
// Thừa kế từ Adw.Window (không phải Gtk.Window)
// Tại sao? Adw.Window có style GNOME hiện đại, tích hợp HeaderBar tự nhiên
//

public class HistoryDialog : Adw.Window {
    // =========================================================================
    // CONSTRUCTOR - Khởi tạo hộp thoại
    // =========================================================================
    //
    // Tham số:
    //   - parent: Cửa sổ cha (BrowserWindow)
    //             Dialog sẽ xuất hiện giữa cửa sổ cha
    //
    public HistoryDialog(Gtk.Window parent) {
        // -----------------------------------------------------------------
        // KHỞI TẠO CƠ BẢN
        // -----------------------------------------------------------------
        //
        // Object(...): Cú pháp Vala để set nhiều properties cùng lúc
        //
        // - transient_for: Cửa sổ cha → Dialog nổi lên trên cửa sổ này
        // - modal: true → User phải đóng dialog trước khi dùng cửa sổ cha
        // - default_width/height: Kích thước mặc định (pixels)
        //
        Object(
            transient_for: parent, 
            modal: true, 
            default_width: 600, 
            default_height: 500
        );
        
        // Đặt tiêu đề cho dialog
        this.title = "History";

        // -----------------------------------------------------------------
        // TẠO LAYOUT CHÍNH - ToolbarView
        // -----------------------------------------------------------------
        //
        // ToolbarView: Container đặc biệt của Adwaita
        // - Có vị trí riêng cho top bar (HeaderBar)
        // - Có vị trí riêng cho content
        // - Có thể có bottom bar
        //
        var toolbar_view = new Adw.ToolbarView();
        set_content(toolbar_view);

        // -----------------------------------------------------------------
        // TẠO HEADER BAR
        // -----------------------------------------------------------------
        //
        // HeaderBar: Thanh tiêu đề với nút đóng, minimize, maximize
        // Trong Adwaita, header bar được tích hợp với cửa sổ
        //
        var header_bar = new Adw.HeaderBar();
        toolbar_view.add_top_bar(header_bar);

        // -----------------------------------------------------------------
        // TẠO NÚT XÓA LỊCH SỬ
        // -----------------------------------------------------------------
        //
        // Button.with_label(): Tạo button có text
        // add_css_class("destructive-action"): Style màu đỏ (destructive)
        //   → Cảnh báo user rằng action này không thể undo
        //
        var clear_button = new Button.with_label("Clear");
        clear_button.add_css_class("destructive-action");
        
        // Connect signal "clicked"
        // Lambda expression: () => { ... }
        //   → Hàm ẩn danh được gọi khi button clicked
        clear_button.clicked.connect(() => {
            // Xóa toàn bộ lịch sử
            HistoryManager.get_default().clear();
            
            // Đóng dialog
            // close() thay vì destroy() để dialog có thể tái sử dụng
            close();
        });
        
        // Đặt button ở bên trái header bar
        header_bar.pack_start(clear_button);

        // -----------------------------------------------------------------
        // TẠO CONTAINER CHO NỘI DUNG
        // -----------------------------------------------------------------
        //
        // Box: Container xếp các widget theo hàng (VERTICAL) hoặc cột (HORIZONTAL)
        // ScrolledWindow: Cho phép scroll khi nội dung quá dài
        //
        var box = new Box(Orientation.VERTICAL, 0);  // 0 = spacing giữa các child
        var scroll = new ScrolledWindow();
        scroll.set_child(box);
        toolbar_view.set_content(scroll);

        // -----------------------------------------------------------------
        // TẠO LISTBOX ĐỂ HIỂN THỊ LỊCH SỬ
        // -----------------------------------------------------------------
        //
        // ListBox: Container đặc biệt cho danh sách
        // - Mỗi child là một "row"
        // - Có thể click để chọn row
        // - Có keyboard navigation (↑↓ keys)
        //
        var list_box = new ListBox();
        
        // CSS classes để style:
        // - "boxed-list": Style box với border và background
        list_box.add_css_class("boxed-list");
        
        // Margins để spacing từ viền
        list_box.margin_top = 12;
        list_box.margin_bottom = 12;
        list_box.margin_start = 12;    // Bên trái
        list_box.margin_end = 12;      // Bên phải
        
        box.append(list_box);

        // -----------------------------------------------------------------
        // LOAD VÀ HIỂN THỊ LỊCH SỬ
        // -----------------------------------------------------------------
        
        var history = HistoryManager.get_default().get_all();
        
        // Trường hợp chưa có lịch sử
        if (history.length == 0) {
             var row = new Adw.ActionRow();
             row.title = "No history found";
             list_box.append(row);
        }

        // Duyệt qua từng mục lịch sử và tạo row
        for (int i = 0; i < history.length; i++) {
            var item = history[i];
            
            // -----------------------------------------------------------------
            // TẠO ACTION ROW CHO MỖI MỤC LỊCH SỬ
            // -----------------------------------------------------------------
            //
            // ActionRow: Row đặc biệt của Adwaita
            // - Có title (text chính)
            // - Có subtitle (text phụ, nhỏ hơn)
            // - Có thể activatable (click được)
            // - Có thể có suffix widget (icon, button...)
            //
            var row = new Adw.ActionRow();
            
            // Title: Hiển thị tiêu đề trang hoặc URL nếu không có title
            // Markup.escape_text(): Escape các ký tự đặc biệt (<, >, &...)
            //   → Tránh lỗi khi title chứa HTML-like text
            row.title = GLib.Markup.escape_text(item.title != "" ? item.title : item.url);
            
            // Subtitle: Hiển thị URL
            row.subtitle = GLib.Markup.escape_text(item.url);
            
            // Cho phép click vào row
            row.activatable = true;
            
            // -----------------------------------------------------------------
            // XỬ LÝ SỰ KIỆN CLICK VÀO ROW
            // -----------------------------------------------------------------
            //
            // Khi user click vào một mục lịch sử:
            //   1. Emit signal "open_url" với URL của mục đó
            //   2. Đóng dialog
            //
            // Signal open_url được định nghĩa ở cuối class
            // window.vala sẽ connect vào signal này để mở URL
            //
            row.activated.connect(() => {
                // Emit signal với URL
                open_url(item.url);
                
                // Đóng dialog
                close();
            });
            
            // Thêm row vào list
            list_box.append(row);
        }
    }
    
    // =========================================================================
    // SIGNAL ĐỊNH NGHĨA - Open URL
    // =========================================================================
    //
    // Signal là cách để widget thông báo sự kiện cho bên ngoài
    //
    // "public signal void open_url(string url)":
    //   - public: Có thể truy cập từ bên ngoài class
    //   - signal: Đây là một signal, không phải method
    //   - void: Không trả về giá trị
    //   - open_url: Tên signal
    //   - (string url): Tham số được gửi kèm khi emit
    //
    // Cách sử dụng từ bên ngoài (window.vala):
    //
    //   var dialog = new HistoryDialog(this);
    //   
    //   // Connect để lắng nghe signal
    //   dialog.open_url.connect((url) => {
    //       // Mở URL trong tab mới
    //       add_tab(url);
    //   });
    //   
    //   dialog.present();
    //
    // Khi user click vào mục lịch sử:
    //   1. row.activated được emit
    //   2. Lambda function chạy: open_url(item.url)
    //   3. open_url signal được emit
    //   4. window.vala nhận được URL và mở tab mới
    //
    public signal void open_url(string url);
}

// =============================================================================
// 📝 LUỒNG HOẠT ĐỘNG CỦA HISTORY DIALOG
// =============================================================================
//
// 1. User click nút "History" trong window
//
// 2. window.vala tạo HistoryDialog và connect signal:
//    var dialog = new HistoryDialog(this);
//    dialog.open_url.connect((url) => { add_tab(url); });
//    dialog.present();
//
// 3. Dialog hiển thị danh sách lịch sử
//
// 4. User click vào một mục:
//    a) row.activated signal được emit
//    b) Lambda: open_url(item.url) được gọi
//    c) open_url signal emit với URL
//    d) window.vala nhận URL và gọi add_tab(url)
//    e) Dialog đóng
//
// 5. Hoặc user click "Clear":
//    a) HistoryManager.clear() xóa lịch sử
//    b) Dialog đóng
//
// =============================================================================
