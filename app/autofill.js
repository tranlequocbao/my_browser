// =============================================================================
// FILE: autofill.js - SCRIPT TỰ ĐỘNG PHÁT HIỆN VÀ ĐIỀN MẬT KHẨU
// =============================================================================
//
// 📚 KIẾN THỨC NỀN TẢNG:
// -----------------------
// 1. SCRIPT INJECTION là gì?
//    - Là kỹ thuật "tiêm" mã JavaScript vào trang web
//    - Script này được chạy trong context của trang web
//    - Có thể tương tác với DOM (Document Object Model) của trang
//
// 2. IIFE (Immediately Invoked Function Expression) là gì?
//    - Là hàm được định nghĩa VÀ thực thi ngay lập tức
//    - Tạo scope riêng, tránh xung đột biến với code của trang web
//    - Cú pháp: (function() { ... })();
//
// 3. DOM (Document Object Model) là gì?
//    - Cấu trúc cây đại diện cho nội dung HTML
//    - Cho phép JavaScript đọc/thay đổi nội dung trang
//    - VD: document.getElementById(), element.value, element.style
//
// 4. EVENT LISTENERS là gì?
//    - Cơ chế lắng nghe các sự kiện (click, keydown, submit...)
//    - Khi sự kiện xảy ra, hàm callback được gọi
//    - VD: button.addEventListener('click', function() { ... })
//
// 5. WEBKIT MESSAGE HANDLERS là gì?
//    - Cầu nối giữa JavaScript (trong web) và Vala (native code)
//    - JS gửi tin nhắn: webkit.messageHandlers.xxx.postMessage(data)
//    - Vala nhận tin nhắn trong callback đã đăng ký
//
// =============================================================================
//
// 📊 SƠ ĐỒ HOẠT ĐỘNG:
//
// ┌─────────────────────────────────────────────────────────────────────┐
// │                          TRANG WEB                                  │
// │                                                                     │
// │   ┌─────────────────────────────────────────────────────────────┐  │
// │   │  Form đăng nhập                                             │  │
// │   │  ┌───────────────────────────────────────────────────────┐  │  │
// │   │  │ Username: [_____________________________]              │  │  │
// │   │  │ Password: [_____________________________]              │  │  │
// │   │  │                            [   Login   ]               │  │  │
// │   │  └───────────────────────────────────────────────────────┘  │  │
// │   └─────────────────────────────────────────────────────────────┘  │
// │                                                                     │
// │   autofill.js (đang chạy trong trang)                              │
// │   ├── Bước 1: Lắng nghe focus vào ô input                          │
// │   ├── Bước 2: Gửi request_credentials đến Vala                     │
// │   ├── Bước 3: Hiển thị popup với credentials đã lưu                │
// │   ├── Bước 4: User chọn → Điền vào form                            │
// │   └── Bước 5: User submit → Gửi save_password đến Vala             │
// │                                                                     │
// └─────────────────────────────────────────────────────────────────────┘
//                                  │
//                                  │ webkit.messageHandlers
//                                  ▼
// ┌─────────────────────────────────────────────────────────────────────┐
// │                         window.vala (Backend)                       │
// │   - Nhận tin nhắn JSON từ JavaScript                               │
// │   - Gọi CredentialManager để lưu/lấy mật khẩu                     │
// │   - Gọi lại JavaScript để điền credentials                         │
// └─────────────────────────────────────────────────────────────────────┘
//
// =============================================================================

// -----------------------------------------------------------------------------
// IIFE - Immediately Invoked Function Expression
// -----------------------------------------------------------------------------
//
// (function() { ... })();
//
// Tại sao dùng IIFE?
//   1. Tạo scope riêng cho biến: var, function không lọt ra ngoài
//   2. Tránh xung đột với biến của trang web
//   3. Best practice cho script injection
//
// Ví dụ vấn đề nếu KHÔNG dùng IIFE:
//   - Ta định nghĩa: var username = "test";
//   - Trang web cũng có: var username = "admin";
//   - → Xung đột! Không biết username là gì
//
// Với IIFE:
//   - var của ta nằm trong function scope
//   - Không ảnh hưởng đến global scope của trang web
//

(function () {
    // =========================================================================
    // PHẦN 1: KHỞI TẠO VÀ LOGGING
    // =========================================================================
    //
    // console.log() in ra Developer Console (F12 trong trình duyệt)
    // Trong My Browser, log này được forward về terminal của Vala
    // Xem window.vala để hiểu cách forward hoạt động
    //
    console.log("Autofill script loaded - V3");

    // =========================================================================
    // PHẦN 2: BIẾN TRẠNG THÁI (State Variables)
    // =========================================================================
    //
    // Các biến để theo dõi trạng thái hiện tại của script
    //

    // Ô input đang được focus hiện tại
    // null khi không có ô nào được focus
    var currentFocusedInput = null;

    // Ô input cuối cùng đã yêu cầu credentials
    // Dùng để xác định vị trí hiện popup
    var lastRequestedInput = null;

    // Trạng thái popup đang hiện hay không
    // Dùng để tránh hide popup quá sớm
    var popupVisible = false;

    // =========================================================================
    // PHẦN 3: HÀM XỬ LÝ LƯU MẬT KHẨU (Core Handler)
    // =========================================================================
    //
    // Hàm này được gọi khi phát hiện user vừa đăng nhập
    // Gửi yêu cầu lưu mật khẩu đến Vala
    //
    // Tham số:
    //   - username: Tên đăng nhập mà user vừa nhập
    //   - password: Mật khẩu mà user vừa nhập
    //
    function handleSubmission(username, password) {
        // Chỉ xử lý nếu có CẢ username VÀ password
        if (username && password) {
            console.log("Detected login attempt (handling): " + username);

            // -----------------------------------------------------------------
            // GỬI TIN NHẮN ĐẾN VALA QUA WEBKIT MESSAGE HANDLER
            // -----------------------------------------------------------------
            //
            // Kiểm tra sự tồn tại của message handler:
            //   - window.webkit: Object chứa các API của WebKit
            //   - window.webkit.messageHandlers: Các handlers đã đăng ký
            //   - password_manager: Handler cụ thể cho password management
            //
            // Handler được đăng ký trong window.vala:
            //   content_manager.register_script_message_handler("password_manager", null);
            //
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.password_manager) {
                // postMessage(): Gửi tin nhắn đến Vala
                // JSON.stringify(): Chuyển object thành chuỗi JSON
                //   { action: 'save_password', ... } → '{"action":"save_password",...}'
                //
                window.webkit.messageHandlers.password_manager.postMessage(JSON.stringify({
                    action: 'save_password',       // Loại hành động
                    username: username,             // Tên đăng nhập
                    password: password,             // Mật khẩu
                    url: window.location.href       // URL hiện tại (VD: https://facebook.com/login)
                }));
            }
        }
    }

    // =========================================================================
    // PHẦN 4: PHÁT HIỆN FOCUS VÀO Ô INPUT (Focus Detection)
    // =========================================================================
    //
    // Khi user click vào ô username/password, ta sẽ:
    //   1. Gửi yêu cầu lấy credentials đã lưu
    //   2. Hiển thị popup để user chọn (nếu có)
    //

    function setupFocusDetection() {
        // -----------------------------------------------------------------
        // LẮNG NGHE SỰ KIỆN FOCUSIN
        // -----------------------------------------------------------------
        //
        // 'focusin': Sự kiện khi một element được focus
        // Khác với 'focus': focusin bubbles up đến parent elements
        //
        // document.addEventListener(eventType, callback, useCapture):
        //   - eventType: Tên sự kiện ('click', 'focusin', ...)
        //   - callback: Hàm được gọi khi sự kiện xảy ra
        //   - useCapture (true): Bắt sự kiện trong capture phase (sớm nhất)
        //
        // Capture vs Bubble:
        //   Capture: document → html → body → div → input (từ ngoài vào)
        //   Bubble:  input → div → body → html → document (từ trong ra)
        //
        document.addEventListener('focusin', function (e) {
            // e: Event object chứa thông tin về sự kiện
            // e.target: Element đã trigger sự kiện
            var target = e.target;

            // -----------------------------------------------------------------
            // KIỂM TRA CÓ PHẢI Ô INPUT KHÔNG
            // -----------------------------------------------------------------
            //
            // tagName: Tên tag HTML của element (INPUT, BUTTON, DIV...)
            // type: Loại input (text, email, password, checkbox...)
            //
            if (target.tagName === 'INPUT' &&
                (target.type === 'text' || target.type === 'email' || target.type === 'password')) {

                // Kiểm tra xem ô input này có thuộc form đăng nhập không
                var isLoginField = isLoginFormField(target);

                if (isLoginField) {
                    // Lưu reference đến input đang focus
                    currentFocusedInput = target;
                    lastRequestedInput = target;

                    // -----------------------------------------------------------------
                    // LẤY VỊ TRÍ CỦA Ô INPUT TRÊN MÀN HÌNH
                    // -----------------------------------------------------------------
                    //
                    // getBoundingClientRect(): Trả về DOMRect object
                    //   - left, right, top, bottom: Tọa độ relative to viewport
                    //   - width, height: Kích thước element
                    //
                    var rect = target.getBoundingClientRect();

                    console.log("Login field focused, requesting credentials");

                    // -----------------------------------------------------------------
                    // GỬI YÊU CẦU LẤY CREDENTIALS ĐÃ LƯU
                    // -----------------------------------------------------------------
                    //
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.password_manager) {
                        window.webkit.messageHandlers.password_manager.postMessage(JSON.stringify({
                            action: 'request_credentials',    // Yêu cầu credentials
                            url: window.location.href,        // URL hiện tại
                            fieldType: target.type,           // Loại field (text/email/password)
                            position: {
                                // Tọa độ để hiện popup
                                // scrollX/Y: Scroll offset của trang
                                // Math.round(): Làm tròn số
                                x: Math.round(rect.left + window.scrollX),
                                y: Math.round(rect.bottom + window.scrollY),
                                width: Math.round(rect.width),
                                height: Math.round(rect.height)
                            }
                        }));
                    }
                }
            }
        }, true);  // true = capture phase

        // -----------------------------------------------------------------
        // LẮNG NGHE SỰ KIỆN FOCUSOUT
        // -----------------------------------------------------------------
        //
        // 'focusout': Sự kiện khi element mất focus
        // Dùng để ẩn popup nếu cần
        //
        document.addEventListener('focusout', function (e) {
            // Không ẩn ngay nếu popup đang hiển thị
            // Cho phép user click vào popup
            if (!popupVisible) {
                // setTimeout: Đợi 300ms trước khi clear
                // Cho phép focus chuyển sang popup
                setTimeout(function () {
                    if (!popupVisible) {
                        currentFocusedInput = null;
                    }
                }, 300);
            }
        }, true);
    }

    // =========================================================================
    // PHẦN 5: KIỂM TRA FORM ĐĂNG NHẬP (Login Form Detection)
    // =========================================================================
    //
    // Hàm này kiểm tra xem ô input có phải là một phần của form đăng nhập không
    //
    // Tại sao cần kiểm tra?
    //   - Không phải mọi ô input đều là form đăng nhập
    //   - VD: Ô tìm kiếm, comment box, form liên hệ...
    //   - Chỉ muốn trigger autofill cho form đăng nhập
    //
    // Tham số:
    //   - input: Element input cần kiểm tra
    //
    // Trả về:
    //   - true: Có khả năng là form đăng nhập
    //   - false: Không phải form đăng nhập
    //
    function isLoginFormField(input) {
        // -----------------------------------------------------------------
        // CÁCH 1: KIỂM TRA CÓ Ô PASSWORD GẦN ĐÓ KHÔNG
        // -----------------------------------------------------------------
        //
        // Logic: Nếu form có ô password → Khả năng cao là form đăng nhập
        //
        // input.form: Reference đến <form> chứa input này
        //             null nếu input không nằm trong form nào
        //
        var form = input.form || document;  // Fallback về document nếu không có form
        var inputs = form.getElementsByTagName('input');

        for (var i = 0; i < inputs.length; i++) {
            if (inputs[i].type === 'password') {
                return true;  // Có ô password → là form đăng nhập
            }
        }

        // -----------------------------------------------------------------
        // CÁCH 2: KIỂM TRA TÊN/ID CỦA Ô INPUT
        // -----------------------------------------------------------------
        //
        // Logic: Nếu name/id/placeholder chứa từ khóa đăng nhập → Có khả năng
        //
        // VD: <input name="username">, <input id="email">, <input placeholder="Password">
        //

        // Ghép name, id, placeholder thành một string và chuyển thành lowercase
        var nameId = (input.name + ' ' + input.id + ' ' + input.placeholder).toLowerCase();

        // Các từ khóa thường gặp trong form đăng nhập
        var loginPatterns = ['user', 'email', 'login', 'password', 'pass', 'pwd'];

        for (var i = 0; i < loginPatterns.length; i++) {
            // indexOf(): Trả về vị trí của substring, -1 nếu không tìm thấy
            if (nameId.indexOf(loginPatterns[i]) !== -1) {
                return true;  // Tìm thấy từ khóa → Có khả năng là form đăng nhập
            }
        }

        return false;  // Không tìm thấy dấu hiệu → Không phải form đăng nhập
    }

    // =========================================================================
    // PHẦN 6: PHÁT HIỆN HÀNH ĐỘNG ĐĂNG NHẬP (Login Detection Heuristics)
    // =========================================================================
    //
    // "Heuristic" = Phương pháp dựa trên kinh nghiệm, không phải quy tắc chính xác
    //
    // Vấn đề: Làm sao biết user vừa đăng nhập?
    //   - Form cổ điển: submit event
    //   - AJAX/SPA modern: Không có submit event thông thường
    //
    // Giải pháp: Dùng nhiều heuristics kết hợp
    //

    // -----------------------------------------------------------------
    // HEURISTIC 1: Submit Form Chuẩn
    // -----------------------------------------------------------------
    //
    // Phát hiện khi <form> được submit theo cách truyền thống
    // e.target là <form> element
    //
    document.addEventListener('submit', function (e) {
        console.log("Form submit detected");
        processSubmission(e.target);
    }, true);

    // -----------------------------------------------------------------
    // HEURISTIC 2: Nhấn Enter Trong Ô Password
    // -----------------------------------------------------------------
    //
    // Nhiều trang web hiện đại dùng AJAX, không submit form truyền thống
    // Nhấn Enter trong ô password thường trigger login
    //
    // keydown: Sự kiện khi phím được nhấn xuống
    // e.key: Tên phím ('Enter', 'Escape', 'a', 'b', ...)
    //
    document.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' && e.target.type === 'password') {
            console.log("Enter key on password field");
            // e.target.form: Form chứa ô password
            // Fallback về document nếu không có form
            processSubmission(e.target.form || document);
        }
    }, true);

    // -----------------------------------------------------------------
    // HEURISTIC 3: Click Vào Nút Submit/Login
    // -----------------------------------------------------------------
    //
    // Phát hiện khi user click vào nút có vẻ là nút đăng nhập
    //
    document.addEventListener('click', function (e) {
        var target = e.target;

        // Kiểm tra có phải nút submit không
        // type='submit': Nút submit form
        // tagName='BUTTON' && type != 'reset': Button thông thường (không phải reset)
        if (target.type === 'submit' || (target.tagName === 'BUTTON' && target.type !== 'reset')) {
            // Tìm xem có ô password đã điền chưa
            var inputs = document.getElementsByTagName('input');
            for (var i = 0; i < inputs.length; i++) {
                // Nếu có ô password có giá trị → User đang đăng nhập
                if (inputs[i].type === 'password' && inputs[i].value.length > 0) {
                    console.log("Click on potential login button");
                    processSubmission(document);
                    break;
                }
            }
        }
    }, true);

    // =========================================================================
    // PHẦN 7: THU THẬP THÔNG TIN ĐĂNG NHẬP (Credential Extraction)
    // =========================================================================
    //
    // Hàm này tìm và thu thập username/password từ trang web
    //
    // Tham số:
    //   - context: Element hoặc document để tìm trong đó
    //
    function processSubmission(context) {
        // Xác định root element để tìm
        // Nếu context có getElementsByTagName → Dùng context
        // Nếu không → Dùng document
        var root = context && context.getElementsByTagName ? context : document;
        var inputs = root.getElementsByTagName('input');

        var username = '';
        var password = '';

        // -----------------------------------------------------------------
        // TÌM Ô PASSWORD VÀ USERNAME
        // -----------------------------------------------------------------
        //
        // Quy tắc: Username thường nằm ngay TRƯỚC ô password
        //
        for (var i = 0; i < inputs.length; i++) {
            var input = inputs[i];

            if (input.type === 'password') {
                // Lấy giá trị password
                password = input.value;

                // Tìm username (ô ngay trước ô password)
                if (i > 0) {
                    var prev = inputs[i - 1];
                    if (prev.type === 'text' || prev.type === 'email') {
                        username = prev.value;
                    }
                }

                // Nếu đã tìm được password thì dừng
                if (password) break;
            }
        }

        // -----------------------------------------------------------------
        // FALLBACK: TÌM USERNAME NẾU CHƯA TÌM ĐƯỢC
        // -----------------------------------------------------------------
        //
        // Nếu có password nhưng chưa tìm được username
        // Tìm trong toàn bộ document
        //
        if (password && !username) {
            var allInputs = document.getElementsByTagName('input');
            for (var i = 0; i < allInputs.length; i++) {
                // Lấy ô text/email đầu tiên có giá trị
                if ((allInputs[i].type === 'text' || allInputs[i].type === 'email') && allInputs[i].value) {
                    username = allInputs[i].value;
                    break;
                }
            }
        }

        // Gọi hàm xử lý chính
        handleSubmission(username, password);
    }

    // =========================================================================
    // PHẦN 8: TỰ ĐỘNG ĐIỀN MẬT KHẨU (Autofill Function)
    // =========================================================================
    //
    // Hàm này được gọi từ Vala để điền credentials vào form
    //
    // Tại sao đặt trên window object?
    //   - window là global object trong browser
    //   - Cho phép Vala gọi qua: web_view.evaluate_javascript("fillCredentials(...)")
    //
    // Tham số:
    //   - username: Tên đăng nhập cần điền
    //   - password: Mật khẩu cần điền
    //
    // =========================================================================
    // SECURITY TOKEN - Prevent XSS attacks
    // =========================================================================
    //
    // Token được generate và verify bởi Vala backend
    // Malicious scripts không thể guess được token này
    //
    var _securityToken = null;

    // Setter được gọi từ Vala trước khi fill credentials
    window._setAutofillToken = function (token) {
        _securityToken = token;
    };

    // Private function - không expose trực tiếp lên window
    function fillCredentials(username, password, token) {
        // Verify token để ngăn XSS
        if (token !== _securityToken || _securityToken === null) {
            console.warn("[Security] Invalid autofill token, ignoring request");
            return;
        }
        // Clear token after use (one-time use)
        _securityToken = null;

        var inputs = document.getElementsByTagName('input');
        var filled = false;

        for (var i = 0; i < inputs.length; i++) {
            if (inputs[i].type === 'password') {
                // -----------------------------------------------------------------
                // ĐIỀN MẬT KHẨU
                // -----------------------------------------------------------------
                inputs[i].value = password;
                filled = true;

                // -----------------------------------------------------------------
                // TRIGGER EVENTS
                // -----------------------------------------------------------------
                //
                // Một số framework (React, Angular, Vue...) lắng nghe events
                // để update internal state, không chỉ đọc .value
                //
                // dispatchEvent(): Trigger một event
                // new Event(): Tạo event mới
                //   - 'input': Event type cho input change
                //   - bubbles: true cho phép event bubble up
                //
                inputs[i].dispatchEvent(new Event('input', { bubbles: true }));
                inputs[i].dispatchEvent(new Event('change', { bubbles: true }));

                // -----------------------------------------------------------------
                // ĐIỀN USERNAME (ô ngay trước ô password)
                // -----------------------------------------------------------------
                if (i > 0) {
                    var prevInput = inputs[i - 1];
                    if (prevInput.type === 'text' || prevInput.type === 'email') {
                        prevInput.value = username;
                        prevInput.dispatchEvent(new Event('input', { bubbles: true }));
                        prevInput.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                }
                break;
            }
        }

        if (!filled) console.warn("[Autofill] No password field found");
    }

    // =========================================================================
    // SECURE FILL - Public interface with token verification  
    // =========================================================================
    //
    // Được gọi từ Vala với token để verify request hợp lệ
    //
    window.fillCredentialsSecure = function (username, password, token) {
        fillCredentials(username, password, token);
    };

    // Khởi tạo focus detection
    setupFocusDetection();

    // =========================================================================
    // PHẦN 9: POPUP HIỂN THỊ CREDENTIALS ĐÃ LƯU
    // =========================================================================
    //
    // Biến lưu reference đến popup element
    // null khi popup chưa được tạo hoặc đã bị xóa
    //
    var credentialPopup = null;

    // =========================================================================
    // HÀM TẠO VÀ HIỂN THỊ POPUP
    // =========================================================================
    //
    // Được gọi từ Vala khi có credentials đã lưu cho URL hiện tại
    //
    // Tham số:
    //   - username: Username cần hiển thị trong popup
    //
    window.showCredentialPopup = function (username) {
        // Removed sensitive logging for security

        // Xóa popup cũ nếu có
        hideCredentialPopup();

        // Xác định input để định vị popup
        var targetInput = lastRequestedInput || currentFocusedInput;
        if (!targetInput) {
            console.log("No input target for popup");
            return;
        }

        // Đánh dấu popup đang hiển thị
        popupVisible = true;

        // -----------------------------------------------------------------
        // TẠO POPUP ELEMENT
        // -----------------------------------------------------------------
        //
        // document.createElement(): Tạo element HTML mới
        // element.style.cssText: Set nhiều CSS styles cùng lúc
        //
        credentialPopup = document.createElement('div');
        credentialPopup.id = 'credential-popup';

        // CSS styles cho popup
        // Template literal (backtick): Cho phép viết string nhiều dòng
        credentialPopup.style.cssText = `
            position: absolute;
            background: #fff;
            border: 1px solid #ccc;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 999999;
            min-width: 200px;
            max-width: 300px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            overflow: hidden;
        `;

        // -----------------------------------------------------------------
        // TẠO CREDENTIAL ITEM
        // -----------------------------------------------------------------
        //
        // Mỗi item là một row có thể click
        //
        var item = document.createElement('div');
        item.style.cssText = `
            padding: 12px 16px;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 10px;
            transition: background 0.15s;
        `;

        // Hover effects
        // onmouseenter/onmouseleave: Events khi mouse vào/ra element
        item.onmouseenter = function () { this.style.background = '#f0f0f0'; };
        item.onmouseleave = function () { this.style.background = '#fff'; };

        // Icon
        var icon = document.createElement('span');
        icon.style.cssText = 'font-size: 18px;';
        icon.textContent = '🔐';
        item.appendChild(icon);

        // Username text
        var text = document.createElement('span');
        text.style.cssText = 'flex: 1; color: #333;';
        text.textContent = username;
        item.appendChild(text);

        // -----------------------------------------------------------------
        // XỬ LÝ CLICK VÀO ITEM
        // -----------------------------------------------------------------
        //
        // Khi user click → Yêu cầu Vala điền credentials
        //
        item.onclick = function (e) {
            // e.preventDefault(): Ngăn hành động mặc định (nếu có)
            // e.stopPropagation(): Ngăn event bubble lên parent
            e.preventDefault();
            e.stopPropagation();

            // Removed sensitive logging for security

            // Gửi yêu cầu fill_credential đến Vala
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.password_manager) {
                window.webkit.messageHandlers.password_manager.postMessage(JSON.stringify({
                    action: 'fill_credential',
                    url: window.location.href,
                    username: username
                }));
            }

            // Ẩn popup
            hideCredentialPopup();
        };

        // Thêm item vào popup
        credentialPopup.appendChild(item);

        // -----------------------------------------------------------------
        // ĐỊNH VỊ POPUP NGAY DƯỚI Ô INPUT
        // -----------------------------------------------------------------
        //
        var rect = targetInput.getBoundingClientRect();
        credentialPopup.style.left = (rect.left + window.scrollX) + 'px';
        credentialPopup.style.top = (rect.bottom + window.scrollY + 4) + 'px';  // +4px gap
        credentialPopup.style.minWidth = rect.width + 'px';

        // Thêm popup vào body
        document.body.appendChild(credentialPopup);

        // -----------------------------------------------------------------
        // ĐÓNG POPUP KHI CLICK BÊN NGOÀI
        // -----------------------------------------------------------------
        //
        // setTimeout: Đợi 300ms để tránh close ngay khi vừa mở
        //
        setTimeout(function () {
            document.addEventListener('click', hideCredentialPopupOnClick, true);
        }, 300);
    };

    // =========================================================================
    // HÀM ẨN POPUP
    // =========================================================================
    //
    function hideCredentialPopup() {
        if (credentialPopup && credentialPopup.parentNode) {
            // Xóa popup khỏi DOM
            credentialPopup.parentNode.removeChild(credentialPopup);
        }
        credentialPopup = null;
        popupVisible = false;

        // Xóa event listener
        document.removeEventListener('click', hideCredentialPopupOnClick, true);
    }

    // =========================================================================
    // HANDLER: ẨN POPUP KHI CLICK BÊN NGOÀI
    // =========================================================================
    //
    function hideCredentialPopupOnClick(e) {
        // Kiểm tra xem click có ở trong popup không
        // element.contains(): true nếu element chứa target
        if (credentialPopup && !credentialPopup.contains(e.target)) {
            hideCredentialPopup();
        }
    }

})();
// Đóng IIFE - Script kết thúc ở đây

// =============================================================================
// 📝 TÓM TẮT LUỒNG HOẠT ĐỘNG
// =============================================================================
//
// LUỒNG 1: TỰ ĐỘNG ĐIỀN (AUTOFILL)
// ---------------------------------
// 1. User mở trang và click vào ô username/password
// 2. focusin event được trigger
// 3. Script gửi 'request_credentials' đến Vala
// 4. Vala tìm credentials trong Keyring
// 5. Nếu có, Vala gọi window.showCredentialPopup(username)
// 6. Popup hiển thị
// 7. User click vào credential
// 8. Script gửi 'fill_credential' đến Vala
// 9. Vala gọi window.fillCredentials(username, password)
// 10. Script điền vào form
//
// LUỒNG 2: LƯU MẬT KHẨU (SAVE)
// -----------------------------
// 1. User điền username/password và submit
// 2. submit/keydown/click event được trigger
// 3. processSubmission() tìm username/password
// 4. handleSubmission() gửi 'save_password' đến Vala
// 5. Vala hiển thị dialog "Lưu mật khẩu?"
// 6. User chọn Yes → Lưu vào Keyring
//
// =============================================================================
