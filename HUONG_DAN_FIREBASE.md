# HƯỚNG DẪN THIẾT LẬP DỰ ÁN FIREBASE VÀ GOOGLE SIGN-IN

Tài liệu này hướng dẫn chi tiết các bước thiết lập Firebase Console và kích hoạt tính năng **Đăng nhập bằng tài khoản Google** (Google Sign-In) cho ứng dụng **Cashew StudyDocs**.

---

## 1. CÁC THÀNH PHẦN ĐÃ ĐƯỢC TÍCH HỢP SẴN TRONG MÃ NGUỒN

Ứng dụng đã được cấu hình hoàn chỉnh các tầng chức năng theo kiến trúc Cashew:

1. **Thư viện phụ thuộc (`pubspec.yaml`)**:
   - `firebase_core: ^4.15.0`: Khởi tạo và kết nối Firebase đa nền tảng.
   - `firebase_auth: ^6.7.0`: Quản lý phiên xác thực, người dùng và Token.
   - `google_sign_in: ^7.2.0`: Tương tác xác thực tài khoản Google.

2. **Cấu hình đa nền tảng (`lib/firebase_options.dart`)**:
   - Chứa thông số cấu hình Firebase (`DefaultFirebaseOptions`) cho Web, Android, iOS.

3. **Tầng Service (`lib/services/auth_service.dart`)**:
   - Quản lý logic gọi `signInWithGoogle()`, `signOut()`.
   - Hỗ trợ cả Web (Firebase Popup) và Di động (GoogleSignIn API).
   - Tự động bắt lỗi và dịch sang thông báo tiếng Việt thân thiện.
   - Cơ chế fallback an toàn, không làm crash ứng dụng khi chạy Unit Test hoặc khi chưa gắn khóa Firebase thực tế.

4. **Tầng State Management (`lib/state/auth_provider.dart`)**:
   - Lắng nghe sự kiện `authStateChanges` từ Firebase Auth theo thời gian thực.
   - Cung cấp dữ liệu `user`, `displayName`, `email`, `photoUrl`, `isAuthenticated`, `isLoading`, `errorMessage` cho toàn bộ giao diện qua `Provider`.

5. **Tầng Giao diện người dùng (`UI Widgets & Pages`)**:
   - `lib/widgets/google_sign_in_button.dart`: Nút đăng nhập Google chuẩn Material 3 và nhận diện thương hiệu Google.
   - `lib/widgets/user_profile_dialog.dart`: Hộp thoại xem thông tin tài khoản, avatar, trạng thái kết nối Cloud và nút Đăng xuất / Đăng nhập.
   - `lib/pages/home_dashboard_page.dart`: Tích hợp Avatar tài khoản trên AppBar và Thẻ chào mừng/kêu gọi đăng nhập trên Dashboard.

6. **Cấu hình Android Gradle**:
   - `android/settings.gradle.kts`: Đã khai báo plugin `com.google.gms.google-services` (version `4.4.2`).
   - `android/app/build.gradle.kts`: Đã áp dụng `id("com.google.gms.google-services")`.
   - `android/app/google-services.json`: File cấu hình mẫu với package `com.example.projectsth1`.

7. **Cấu hình Web**:
   - `web/index.html`: Đã thêm thẻ `<meta name="google-signin-client_id" ...>`.

---

## 2. CÁC BƯỚC THIẾT LẬP DỰ ÁN TRÊN FIREBASE CONSOLE

Để kết nối ứng dụng với tài khoản Firebase của bạn, vui lòng thực hiện các bước sau:

### Bước 1: Tạo dự án Firebase
1. Truy cập [Firebase Console](https://console.firebase.google.com/).
2. Nhấn **"Add project"** (Thêm dự án) và đặt tên dự án (ví dụ: `cashew-studydocs`).
3. Tắt hoặc bật Google Analytics tùy nhu cầu, sau đó nhấn **"Create project"**.

---

### Bước 2: Kích hoạt Google Sign-In
1. Trong thanh menu bên trái, vào mục **Build** -> **Authentication**.
2. Nhấn nút **"Get started"**.
3. Tại tab **"Sign-in method"**, chọn **Google**.
4. Gạt công tắc sang **Enable** (Bật).
5. Nhập **Project support email** (Email hỗ trợ dự án - chọn email Google của bạn).
6. Nhấn **Save** (Lưu).

---

### Bước 3: Cấu hình cho Nền tảng Android
1. Tại trang chủ Firebase Console, nhấn vào biểu tượng **Android** để thêm ứng dụng.
2. Điền thông tin:
   - **Android package name**: `com.example.projectsth1` *(phải trùng khớp với `namespace` và `applicationId` trong `android/app/build.gradle.kts`)*.
   - **App nickname**: `Cashew StudyDocs`.
   - **Debug signing certificate SHA-1**:
     - Mở terminal tại thư mục dự án và chạy:
       ```bash
       cd android
       ./gradlew signingReport
       ```
     - Sao chép chuỗi mã `SHA1` (thường nằm ở biến thể `debug`) và dán vào ô SHA-1 trên Firebase Console.
3. Nhấn **Register app**.
4. Tải file **`google-services.json`** và sao chép đè vào thư mục:
   ```
   android/app/google-services.json
   ```
5. Nhấn **Next** -> **Continue to console**.

---

### Bước 4: Cấu hình cho Nền tảng Web
1. Tại trang chủ Firebase Console, nhấn vào biểu tượng **Web** `</>` để thêm ứng dụng Web.
2. Đặt tên (ví dụ: `Cashew StudyDocs Web`) -> Nhấn **Register app**.
3. Firebase sẽ hiển thị đoạn mã `firebaseConfig`:
   ```javascript
   const firebaseConfig = {      
     apiKey: "AIzaSy...",
     authDomain: "cashew-studydocs.firebaseapp.com",
     projectId: "cashew-studydocs",
     storageBucket: "cashew-studydocs.appspot.com",
     messagingSenderId: "...",
     appId: "..."
   };
   ```
4. Mở file [lib/firebase_options.dart](file:///d:/PTAPP/PTUDDD_K65/lib/firebase_options.dart) và cập nhật các thông số tương ứng vào `static const FirebaseOptions web = ...`.
5. Vào **Google Cloud Console** (mục Credentials của dự án Firebase), lấy **OAuth 2.0 Web Client ID** và cập nhật vào [web/index.html](file:///d:/PTAPP/PTUDDD_K65/web/index.html):
   ```html
   <meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
   ```

---

## 3. CÁCH SỬ DỤNG VÀ KIỂM THỬ TRONG ỨNG DỤNG

### Chạy ứng dụng trên trình duyệt Web:
```bash
flutter run -d chrome
```
- Khi ứng dụng khởi chạy, nhấn vào biểu tượng **Tài khoản** ở góc trên bên phải thanh AppBar hoặc nhấn vào thẻ **"Đăng nhập với Google"** trên màn hình chính.
- Cửa sổ Google OAuth Popup sẽ xuất hiện để bạn chọn tài khoản Google.
- Sau khi đăng nhập thành công:
  - Tên hiển thị, email và avatar của bạn sẽ xuất hiện trên màn hình.
  - Bạn có thể nhấn vào để xem thông tin chi tiết và đăng xuất bất kỳ lúc nào.

### Chạy ứng dụng trên thiết bị Android:
```bash
flutter run -d <tên_máy_ảo_hoặc_thiết_bị>
```

### Chạy toàn bộ bộ kiểm thử tự động:
```bash
flutter test
```
Tất cả 17 bài test (bao gồm Unit test tầng Nghiệp vụ, DAO CSDL, Widget UI và Tầng Xác thực Auth) sẽ vượt qua 100%.
