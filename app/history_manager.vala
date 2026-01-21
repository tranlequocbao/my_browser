// =============================================================================
// FILE: history_manager.vala - QUẢN LÝ LỊCH SỬ DUYỆT WEB
// =============================================================================
//
// 📚 KIẾN THỨC NỀN TẢNG:
// -----------------------
// 1. JSON là gì?
//    - JavaScript Object Notation - định dạng lưu trữ dữ liệu phổ biến
//    - Dễ đọc với con người, dễ parse với máy
//    - VD: {"name": "John", "age": 25}
//
// 2. STRUCT vs CLASS
//    - Struct: Dữ liệu đơn giản, pass by value, không có inheritance
//    - Class: Phức tạp hơn, pass by reference, có inheritance
//    - Chọn Struct khi chỉ cần nhóm vài trường dữ liệu
//
// 3. SINGLETON PATTERN (giống credential_manager.vala)
//    - Đảm bảo chỉ có MỘT instance quản lý lịch sử
//    - Tất cả các tab đều share chung danh sách lịch sử
//
// =============================================================================
//
// 📁 CẤU TRÚC FILE LỊCH SỬ (history.json):
//
// ~/.local/share/my-browser/history.json
// [
//   {
//     "url": "https://www.google.com",
//     "title": "Google",
//     "timestamp": "2026-01-20T22:00:00+07:00"
//   },
//   {
//     "url": "https://www.facebook.com",
//     "title": "Facebook",
//     "timestamp": "2026-01-20T21:30:00+07:00"
//   }
// ]
//
// =============================================================================

// -----------------------------------------------------------------------------
// PHẦN 1: IMPORT THƯ VIỆN
// -----------------------------------------------------------------------------

using GLib;    // Thư viện cơ bản (files, paths, datetime...)
using Json;    // Thư viện json-glib để đọc/ghi JSON

// -----------------------------------------------------------------------------
// PHẦN 2: STRUCT HISTORYITEM - Định nghĩa cấu trúc một mục lịch sử
// -----------------------------------------------------------------------------
//
// Mỗi trang web bạn truy cập sẽ được lưu thành một HistoryItem
// Struct này định nghĩa các thông tin cần lưu cho mỗi mục
//
// Tại sao dùng Struct thay vì Class?
//   - HistoryItem chỉ chứa dữ liệu đơn giản (3 strings)
//   - Không cần methods phức tạp
//   - Không cần inheritance
//   - Struct nhẹ hơn và nhanh hơn
//

public struct HistoryItem {
    public string url;        // Địa chỉ URL đầy đủ (VD: https://www.google.com/search?q=hello)
    public string title;      // Tiêu đề trang web (VD: "hello - Google Search")
    public string timestamp;  // Thời điểm truy cập (ISO 8601 format)
}

// -----------------------------------------------------------------------------
// PHẦN 3: CLASS HISTORYMANAGER - Quản lý toàn bộ lịch sử
// -----------------------------------------------------------------------------
//
// Chức năng:
//   1. Thêm URL vào lịch sử khi load trang mới
//   2. Lấy danh sách lịch sử để hiển thị
//   3. Xóa toàn bộ lịch sử
//   4. Tự động lưu/đọc từ file JSON
//
// Sử dụng Singleton Pattern:
//   - Gọi qua: HistoryManager.get_default()
//   - Tất cả các tab đều dùng chung instance này
//

public class HistoryManager : GLib.Object {
    // =========================================================================
    // BIẾN STATIC VÀ INSTANCE (Class-level and Instance-level variables)
    // =========================================================================
    
    // Singleton instance
    private static HistoryManager? instance = null;
    
    // GenericArray: Mảng động trong GLib
    // - Tự động resize khi thêm/xóa phần tử
    // - <HistoryItem?>: Kiểu phần tử là HistoryItem (nullable)
    //
    // So sánh với các ngôn ngữ khác:
    //   - Python: list
    //   - Java: ArrayList<HistoryItem>
    //   - C#: List<HistoryItem>
    //   - JavaScript: Array
    //
    private GenericArray<HistoryItem?> history;
    
    // Đường dẫn đến file JSON lưu lịch sử
    private string file_path;

    // =========================================================================
    // SINGLETON GETTER - Lấy instance duy nhất
    // =========================================================================
    
    public static HistoryManager get_default() {
        if (instance == null) {
            instance = new HistoryManager();
        }
        return instance;
    }

    // =========================================================================
    // CONSTRUCTOR - Khởi tạo HistoryManager
    // =========================================================================
    //
    // Việc cần làm khi khởi tạo:
    //   1. Tạo mảng trống để chứa lịch sử
    //   2. Xác định đường dẫn file lưu trữ
    //   3. Load lịch sử từ file (nếu có)
    //
    
    private HistoryManager() {
        // Khởi tạo mảng trống
        history = new GenericArray<HistoryItem?>();
        
        // -----------------------------------------------------------------
        // XÁC ĐỊNH ĐƯỜNG DẪN FILE
        // -----------------------------------------------------------------
        //
        // Environment.get_user_data_dir() trả về:
        //   - Linux: ~/.local/share
        //   - Windows: C:\Users\<user>\AppData\Local
        //   - macOS: ~/Library/Application Support
        //
        // Path.build_filename() nối các phần đường dẫn:
        //   ~/.local/share + "my-browser" + "history.json"
        //   → ~/.local/share/my-browser/history.json
        //
        // Tại sao dùng build_filename thay vì string concatenation?
        //   - Tự động dùng separator đúng (/ trên Linux, \ trên Windows)
        //   - Xử lý các edge case (double slashes, etc.)
        //
        file_path = GLib.Path.build_filename(
            Environment.get_user_data_dir(),  // ~/.local/share
            "my-browser",                      // Thư mục ứng dụng
            "history.json"                     // Tên file
        );
        
        // Load lịch sử từ file (nếu tồn tại)
        load();
    }

    // =========================================================================
    // THÊM MỤC VÀO LỊCH SỬ - Add Entry
    // =========================================================================
    //
    // Được gọi mỗi khi trang web load xong (từ window.vala)
    //
    // Tham số:
    //   - url: Địa chỉ trang web
    //   - title: Tiêu đề trang
    //
    public void add(string url, string title) {
        // -----------------------------------------------------------------
        // VALIDATION - Kiểm tra URL hợp lệ
        // -----------------------------------------------------------------
        //
        // Bỏ qua các URL không cần lưu:
        //   - URL rỗng
        //   - about: pages (about:blank, about:config...)
        //
        if (url == "" || url.has_prefix("about:")) return;

        // -----------------------------------------------------------------
        // TẠO HISTORY ITEM MỚI
        // -----------------------------------------------------------------
        //
        // DateTime.now_local(): Lấy thời gian hiện tại theo timezone local
        // format_iso8601(): Chuyển thành chuỗi ISO 8601
        //   VD: "2026-01-20T22:00:00+07:00"
        //
        // ISO 8601 là chuẩn quốc tế cho định dạng ngày giờ:
        //   - YYYY-MM-DD: Năm-Tháng-Ngày
        //   - T: Separator giữa ngày và giờ
        //   - HH:MM:SS: Giờ:Phút:Giây
        //   - +07:00: Timezone offset (VD: Việt Nam = UTC+7)
        //
        var now = new DateTime.now_local();
        HistoryItem item = { 
            url,                   // URL trang web
            title,                 // Tiêu đề
            now.format_iso8601()   // Thời điểm truy cập
        };
        
        // Thêm vào đầu mảng (mới nhất ở trên cùng)
        // insert(0, item): Chèn vào vị trí 0 (đầu mảng)
        history.insert(0, item);
        
        // Lưu vào file ngay lập tức
        save();
    }

    // =========================================================================
    // LẤY TOÀN BỘ LỊCH SỬ - Get All
    // =========================================================================
    //
    // Trả về mảng chứa tất cả các mục lịch sử
    // Dùng để hiển thị trong HistoryDialog
    //
    public GenericArray<HistoryItem?> get_all() {
        return history;
    }

    // =========================================================================
    // XÓA TOÀN BỘ LỊCH SỬ - Clear All
    // =========================================================================
    //
    // Xóa sạch lịch sử (khi user nhấn nút "Clear" trong dialog)
    //
    public void clear() {
        // Tạo mảng mới rỗng (garbage collector sẽ dọn mảng cũ)
        history = new GenericArray<HistoryItem?>();
        
        // Lưu mảng rỗng vào file (sẽ ghi [] vào JSON)
        save();
    }

    // =========================================================================
    // LƯU LỊCH SỬ VÀO FILE - Save to JSON
    // =========================================================================
    //
    // Chuyển mảng history thành JSON và ghi vào file
    //
    // JSON output sẽ trông như:
    // [
    //   {"url": "...", "title": "...", "timestamp": "..."},
    //   {"url": "...", "title": "...", "timestamp": "..."}
    // ]
    //
    private void save() {
        // -----------------------------------------------------------------
        // TẠO JSON BẰNG JSON.BUILDER
        // -----------------------------------------------------------------
        //
        // Json.Builder là pattern "builder" để tạo JSON:
        //   - begin_array() / end_array(): Tạo []
        //   - begin_object() / end_object(): Tạo {}
        //   - set_member_name(): Đặt tên key
        //   - add_string_value(): Thêm giá trị string
        //
        var builder = new Json.Builder();
        
        // Bắt đầu mảng JSON: [
        builder.begin_array();
        
        // Duyệt qua từng mục lịch sử
        for (int i = 0; i < history.length; i++) {
            var item = history[i];
            
            // Bắt đầu object: {
            builder.begin_object();
            
            // Thêm "url": "..."
            builder.set_member_name("url");
            builder.add_string_value(item.url);
            
            // Thêm "title": "..."
            builder.set_member_name("title");
            builder.add_string_value(item.title);
            
            // Thêm "timestamp": "..."
            builder.set_member_name("timestamp");
            builder.add_string_value(item.timestamp);
            
            // Kết thúc object: }
            builder.end_object();
        }
        
        // Kết thúc mảng: ]
        builder.end_array();

        // -----------------------------------------------------------------
        // GHI JSON RA FILE
        // -----------------------------------------------------------------
        //
        // Json.Generator chuyển đổi JSON tree thành string và ghi file
        //
        var generator = new Json.Generator();
        generator.set_root(builder.get_root());
        
        try {
            // Tạo thư mục cha nếu chưa tồn tại
            // VD: ~/.local/share/my-browser/
            var dir = GLib.Path.get_dirname(file_path);
            if (!FileUtils.test(dir, FileTest.EXISTS)) {
                // 0700 = rwx------
                // Owner có full quyền, others không có quyền gì
                DirUtils.create_with_parents(dir, 0700);
            }
            
            // Ghi JSON vào file
            generator.to_file(file_path);
            
        } catch (Error e) {
            warning("Failed to save history: %s", e.message);
        }
    }

    // =========================================================================
    // ĐỌC LỊCH SỬ TỪ FILE - Load from JSON
    // =========================================================================
    //
    // Đọc file JSON và chuyển thành mảng HistoryItem
    //
    private void load() {
        // Json.Parser đọc và parse JSON từ file/string
        var parser = new Json.Parser();
        
        try {
            // Đọc và parse file JSON
            parser.load_from_file(file_path);
            
            // Lấy root node của JSON
            var root = parser.get_root();
            
            // Kiểm tra xem root có phải là mảng không
            // (file hợp lệ phải bắt đầu bằng [)
            if (root != null && root.get_node_type() == Json.NodeType.ARRAY) {
                var array = root.get_array();
                long length = array.get_length();
                
                // Duyệt qua từng phần tử trong mảng
                for (int i = 0; i < length; i++) {
                    // Lấy object tại vị trí i
                    var obj = array.get_object_element(i);
                    
                    // Tạo HistoryItem từ JSON object
                    HistoryItem item = {
                        obj.get_string_member("url"),
                        obj.get_string_member("title"),
                        obj.get_string_member("timestamp")
                    };
                    
                    // Thêm vào mảng history
                    history.add(item);
                }
            }
            
        } catch (Error e) {
            // -----------------------------------------------------------------
            // XỬ LÝ LỖI ĐỌC FILE
            // -----------------------------------------------------------------
            //
            // FileError.NOENT = File Not Found (No Entry)
            // Đây là trường hợp bình thường khi chạy lần đầu
            // Không cần log warning, chỉ bỏ qua
            //
            if (!(e is FileError.NOENT)) {
                warning("Failed to load history: %s", e.message);
            }
            // Nếu file không tồn tại, history sẽ là mảng rỗng (OK)
        }
    }
}

// =============================================================================
// 📝 CÁCH SỬ DỤNG HISTORY MANAGER
// =============================================================================
//
// 1. THÊM MỤC VÀO LỊCH SỬ (khi load trang xong):
//    HistoryManager.get_default().add(
//        "https://www.google.com/search?q=hello",
//        "hello - Google Search"
//    );
//
// 2. LẤY TOÀN BỘ LỊCH SỬ (để hiển thị):
//    var all = HistoryManager.get_default().get_all();
//    for (int i = 0; i < all.length; i++) {
//        print("URL: %s, Title: %s\n", all[i].url, all[i].title);
//    }
//
// 3. XÓA LỊCH SỬ:
//    HistoryManager.get_default().clear();
//
// =============================================================================
