// =============================================================================
// FILE: credential_manager.vala - QUẢN LÝ MẬT KHẨU AN TOÀN
// =============================================================================
//
// 📚 KIẾN THỨC NỀN TẢNG:
// -----------------------
// 1. GNOME KEYRING là gì?
//    - Là "két sắt" bảo mật của hệ thống Linux
//    - Mã hóa và lưu trữ mật khẩu, keys, certificates
//    - Tự động mở khóa khi user đăng nhập vào máy
//
// 2. LIBSECRET là gì?
//    - Thư viện để giao tiếp với GNOME Keyring
//    - Cung cấp API đơn giản để lưu/lấy mật khẩu
//    - Tuân theo tiêu chuẩn Secret Service (FreeDesktop.org)
//
// 3. SINGLETON PATTERN là gì?
//    - Design pattern đảm bảo chỉ có MỘT instance của class
//    - Dùng khi cần một "điểm truy cập duy nhất" trong toàn ứng dụng
//    - VD: Quản lý database, cài đặt, logging...
//
// =============================================================================
//
// 📊 SƠ ĐỒ HOẠT ĐỘNG:
//
// ┌─────────────────────────────────────────────────────────────────────┐
// │                          ỨNG DỤNG MY BROWSER                        │
// │                                                                     │
// │   window.vala               credential_manager.vala                 │
// │       │                            │                                │
// │       │ save_credential()          │                                │
// │       │ ─────────────────────────> │                                │
// │       │                            │                                │
// │       │         OK                 │ Secret.password_store_sync()   │
// │       │ <───────────────────────── │ ────────────────────────────>  │
// │                                    │                                │
// └────────────────────────────────────│────────────────────────────────┘
//                                      │
//                                      ▼
// ┌─────────────────────────────────────────────────────────────────────┐
// │                          GNOME KEYRING                              │
// │                                                                     │
// │   ┌─────────────────────────────────────────────────────────────┐  │
// │   │  Collection: "Default Keyring"                              │  │
// │   │                                                             │  │
// │   │  ┌────────────────────────────────────────────────────────┐│  │
// │   │  │ Item: "Password for https://facebook.com"              ││  │
// │   │  │ Secret: "username\npassword" (mã hóa AES-256)         ││  │
// │   │  │ Attributes: { url: "https://facebook.com" }           ││  │
// │   │  └────────────────────────────────────────────────────────┘│  │
// │   │                                                             │  │
// │   └─────────────────────────────────────────────────────────────┘  │
// │                                                                     │
// └─────────────────────────────────────────────────────────────────────┘
//
// =============================================================================

// -----------------------------------------------------------------------------
// PHẦN 1: IMPORT THƯ VIỆN
// -----------------------------------------------------------------------------

using GLib;      // Thư viện cơ bản của GNOME (types, strings, files...)
using Secret;    // Thư viện libsecret để quản lý mật khẩu an toàn

// -----------------------------------------------------------------------------
// PHẦN 2: ĐỊNH NGHĨA CLASS CREDENTIALMANAGER
// -----------------------------------------------------------------------------
//
// Class này chịu trách nhiệm:
//   1. Lưu mật khẩu vào GNOME Keyring
//   2. Lấy mật khẩu đã lưu từ Keyring
//   3. Kiểm tra xem mật khẩu đã tồn tại chưa
//
// Sử dụng Singleton Pattern:
//   - Chỉ có MỘT instance CredentialManager trong toàn ứng dụng
//   - Tất cả các phần của app đều dùng chung instance này
//   - Gọi qua: CredentialManager.get_default()
//

public class CredentialManager : Object {
    // =========================================================================
    // BIẾN STATIC (Class-level variables)
    // =========================================================================
    //
    // static: Biến thuộc về CLASS, không phải instance
    //         Tất cả instances (dù có nhiều) đều share chung biến này
    //
    // ?: Cho phép giá trị null
    //    Trong Vala, mặc định objects không thể null
    //    Thêm ? để cho phép: CredentialManager? = null
    //
    
    // Biến lưu instance duy nhất của class (Singleton)
    private static CredentialManager? instance = null;
    
    // Schema: "Khuôn mẫu" định nghĩa cách lưu trữ credential
    // Giống như định nghĩa cấu trúc bảng trong database
    private static Schema schema;

    // =========================================================================
    // SINGLETON GETTER - Lấy instance duy nhất
    // =========================================================================
    //
    // Cách sử dụng:
    //   var manager = CredentialManager.get_default();
    //   manager.save_credential(...);
    //
    // Hoặc ngắn gọn hơn:
    //   CredentialManager.get_default().save_credential(...);
    //
    public static CredentialManager get_default() {
        // Lần đầu tiên gọi: instance == null → Tạo mới
        // Các lần sau: Trả về instance đã tạo
        if (instance == null) {
            // -----------------------------------------------------------------
            // TẠO SCHEMA - Định nghĩa cấu trúc lưu trữ
            // -----------------------------------------------------------------
            //
            // Schema Parameters:
            //   1. "org.example.mybrowser.password"
            //      → ID định danh duy nhất cho loại credential này
            //      → Format: reverse domain + tên loại dữ liệu
            //
            //   2. SchemaFlags.NONE
            //      → Không có flag đặc biệt
            //      → Có thể dùng: DONT_MATCH_NAME để không match theo tên
            //
            //   3. "url", SchemaAttributeType.STRING
            //      → Định nghĩa attribute "url" kiểu STRING
            //      → Dùng để tìm kiếm credential sau này
            //
            schema = new Schema(
                "org.example.mybrowser.password",  // Tên schema
                SchemaFlags.NONE,                   // Flags
                "url", SchemaAttributeType.STRING   // Attribute để tìm kiếm
            );
            
            // Tạo instance duy nhất
            instance = new CredentialManager();
        }
        return instance;
    }

    // =========================================================================
    // PRIVATE CONSTRUCTOR - Chỉ class này mới có thể tạo instance
    // =========================================================================
    //
    // Tại sao private?
    //   - Ngăn không cho code bên ngoài gọi: new CredentialManager()
    //   - Bắt buộc phải dùng: CredentialManager.get_default()
    //   - Đảm bảo Singleton pattern được tuân thủ
    //
    private CredentialManager() {
        // Không cần làm gì, tất cả thiết lập đã trong get_default()
    }

    // =========================================================================
    // LƯU MẬT KHẨU - Save Credential
    // =========================================================================
    //
    // Tham số:
    //   - url: Origin của website (VD: https://facebook.com)
    //   - username: Tên đăng nhập
    //   - password: Mật khẩu
    //
    // Cách hoạt động:
    //   1. Ghép username và password thành một chuỗi
    //   2. Lưu chuỗi đó vào Keyring với attribute "url"
    //   3. Keyring tự động mã hóa bằng khóa của user
    //
    public void save_credential(string url, string username, string password) {
        // -----------------------------------------------------------------
        // GHÉP USERNAME VÀ PASSWORD
        // -----------------------------------------------------------------
        //
        // Tại sao ghép? 
        //   - Secret.password_store_sync() chỉ lưu được 1 chuỗi "secret"
        //   - Để lưu cả username lẫn password, ta ghép chúng lại
        //   - Dùng "\n" (xuống dòng) làm dấu phân cách
        //
        // Format: "username\npassword"
        //   VD: "john@email.com\nmypassword123"
        //
        // Khi lấy ra, ta sẽ split("\n") để tách lại
        //
        string payload = "%s\n%s".printf(username, password);
        
        try {
            // -----------------------------------------------------------------
            // LƯU VÀO GNOME KEYRING
            // -----------------------------------------------------------------
            //
            // Secret.password_store_sync() Parameters:
            //
            //   1. schema
            //      → Schema đã định nghĩa ở trên
            //
            //   2. COLLECTION_DEFAULT
            //      → Lưu vào collection mặc định ("Default Keyring")
            //      → Có thể dùng: COLLECTION_SESSION (chỉ tồn tại trong phiên)
            //
            //   3. "Password for %s".printf(url)
            //      → Label hiển thị trong ứng dụng Passwords (GNOME)
            //      → VD: "Password for https://facebook.com"
            //
            //   4. payload
            //      → Nội dung bí mật cần lưu (username + password)
            //      → Sẽ được mã hóa tự động
            //
            //   5. null
            //      → Cancellable - cho phép hủy operation
            //      → null = không cần hủy
            //
            //   6. "url", url
            //      → Varargs: các cặp key-value attribute
            //      → Dùng để tìm kiếm credential sau này
            //
            Secret.password_store_sync(
                schema,                              // Schema
                COLLECTION_DEFAULT,                  // Collection
                "Password for %s".printf(url),       // Label
                payload,                             // Secret (username\npassword)
                null,                                // Cancellable
                "url", url                           // Attributes để tìm kiếm
            );
            
            // Log thành công (hiện trong terminal khi chạy)
            message("Credential saved for %s", url);
            
        } catch (GLib.Error e) {
            // -----------------------------------------------------------------
            // XỬ LÝ LỖI
            // -----------------------------------------------------------------
            //
            // Các lỗi có thể xảy ra:
            //   - Keyring bị khóa (user chưa đăng nhập)
            //   - Không có quyền truy cập
            //   - D-Bus service không chạy
            //
            warning("Failed to save credential: %s", e.message);
        }
    }

    // =========================================================================
    // CẤU TRÚC DỮ LIỆU CREDENTIAL - Struct Definition
    // =========================================================================
    //
    // Struct: Kiểu dữ liệu tùy chỉnh để nhóm các giá trị liên quan
    // Khác với Class:
    //   - Struct: Light-weight, pass by value
    //   - Class: Heavy-weight, pass by reference
    //
    // Khi nào dùng Struct?
    //   - Dữ liệu đơn giản, chỉ chứa vài trường
    //   - Không cần methods phức tạp
    //   - VD: Point(x, y), Color(r, g, b), Credential(user, pass)
    //
    public struct Credential {
        public string username;  // Tên đăng nhập
        public string password;  // Mật khẩu
    }

    // =========================================================================
    // LẤY MẬT KHẨU ĐÃ LƯU - Get Credential (Synchronous)
    // =========================================================================
    //
    // Tham số:
    //   - url: Origin của website cần tìm
    //
    // Trả về:
    //   - Credential?: struct chứa username/password (nullable)
    //   - null nếu không tìm thấy
    //
    // Tại sao có "Sync" trong tên?
    //   - Sync = Synchronous = Đồng bộ
    //   - Hàm sẽ chờ (block) cho đến khi có kết quả
    //   - Đối lập với Async (không đồng bộ) - không chờ
    //
    public Credential? get_credential_sync(string url) {
         try {
              // ----------------------------------------------------------------
              // TÌM KIẾM TRONG KEYRING
              // ----------------------------------------------------------------
              //
              // Secret.password_lookup_sync() Parameters:
              //   1. schema   → Schema để tìm
              //   2. null     → Cancellable
              //   3. "url", url → Tìm credential có attribute url = giá trị url
              //
              // Trả về:
              //   - Chuỗi secret nếu tìm thấy
              //   - null nếu không tìm thấy
              //
              string? payload = Secret.password_lookup_sync(schema, null, "url", url);
              
              if (payload != null) {
                  // ---------------------------------------------------------------
                  // TÁCH USERNAME VÀ PASSWORD
                  // ---------------------------------------------------------------
                  //
                  // payload = "username\npassword"
                  // split("\n", 2): Tách theo "\n", tối đa 2 phần
                  //   → ["username", "password"]
                  //
                  // Tại sao giới hạn 2?
                  //   - Phòng trường hợp password chứa "\n"
                  //   - VD: "user\npass\nword123" → ["user", "pass\nword123"]
                  //
                  string[] parts = payload.split("\n", 2);
                  
                  if (parts.length == 2) {
                      // Trả về Credential struct
                      // Cú pháp Vala: { field1, field2 } để khởi tạo struct
                      return { parts[0], parts[1] };
                  }
              }
         } catch (GLib.Error e) {
              warning("Failed to lookup credential: %s", e.message);
         }
         
         // Không tìm thấy hoặc có lỗi
         return null;
    }
    
    // =========================================================================
    // KIỂM TRA CREDENTIAL ĐÃ TỒN TẠI - Check Existing
    // =========================================================================
    //
    // Mục đích:
    //   - Tránh hỏi lưu mật khẩu khi đã lưu rồi
    //   - Kiểm tra cả URL và username phải khớp
    //
    // Tham số:
    //   - url: Origin của website
    //   - username: Tên đăng nhập cần kiểm tra
    //
    // Trả về:
    //   - true: Credential đã tồn tại với cùng URL và username
    //   - false: Chưa tồn tại hoặc username khác
    //
    public bool has_credential(string url, string username) {
        // Lấy credential đã lưu cho URL này
        var cred = get_credential_sync(url);
        
        // Kiểm tra:
        //   1. cred != null: Có credential cho URL này
        //   2. cred.username == username: Username trùng khớp
        if (cred != null && cred.username == username) {
            return true;
        }
        return false;
    }
}

// =============================================================================
// 📝 CÁCH SỬ DỤNG CREDENTIAL MANAGER
// =============================================================================
//
// 1. LƯU MẬT KHẨU:
//    CredentialManager.get_default().save_credential(
//        "https://facebook.com",  // URL
//        "user@email.com",        // Username
//        "mypassword123"          // Password
//    );
//
// 2. LẤY MẬT KHẨU:
//    var cred = CredentialManager.get_default().get_credential_sync("https://facebook.com");
//    if (cred != null) {
//        print("Username: %s\n", cred.username);
//        print("Password: %s\n", cred.password);
//    }
//
// 3. KIỂM TRA TỒN TẠI:
//    if (CredentialManager.get_default().has_credential("https://facebook.com", "user@email.com")) {
//        print("Credential already saved!\n");
//    }
//
// =============================================================================
//
// 📁 VỊ TRÍ LƯU TRỮ:
// ------------------
// - Credentials được lưu trong GNOME Keyring
// - File database: ~/.local/share/keyrings/default.keyring
// - Xem bằng ứng dụng "Passwords" (gnome-secrets) hoặc Seahorse
//
// =============================================================================
