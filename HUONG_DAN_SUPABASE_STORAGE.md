# HƯỚNG DẪN THIẾT LẬP FIREBASE STORAGE & SUPABASE DATABASE

Tài liệu này hướng dẫn chi tiết về cấu trúc lưu trữ Firebase Storage, thiết kế cơ sở dữ liệu Supabase, các chính sách bảo mật Row Level Security (RLS), và các tính năng chia sẻ/phân quyền tài liệu.

---

## 1. CẤU TRÚC LƯU TRỮ TRÊN FIREBASE STORAGE

Ứng dụng quản lý tệp tin trên Firebase Storage theo cấu trúc phân cấp chuẩn REST:

```
documents/
  └── {userId}/
        └── {documentId}/
              └── {sanitizedFileName}
```

### Ưu điểm của cấu trúc này:
1. **Phân vùng người dùng (`{userId}`)**: Dễ dàng áp dụng Firebase Storage Security Rules theo từng người dùng (chỉ người tạo mới có quyền ghi vào thư mục của mình).
2. **Định danh tài liệu (`{documentId}`)**: Cho phép mỗi tài liệu có thể lưu trữ nhiều phiên bản hoặc tệp đính kèm mà không bị trùng lặp tên.
3. **Chuẩn hóa tên tệp (`{sanitizedFileName}`)**: Loại bỏ các ký tự đặc biệt nguy hiểm trước khi lưu vào bucket.
4. **Metadata đính kèm**: Lưu trữ `userId`, `documentId`, `originalName`, `uploadedAt` phục vụ tra cứu.

### Mã triển khai dịch vụ:
- [lib/services/firebase_storage_service.dart](file:///d:/PTAPP/PTUDDD_K65/lib/services/firebase_storage_service.dart): Cung cấp hàm `uploadDocumentFile(...)` và `deleteDocumentFile(...)` hoạt động đa nền tảng (Web, Android, iOS).

---

## 2. THIẾT KẾ CƠ SỞ DỮ LIỆU TRÊN SUPABASE

File mã nguồn SQL khởi tạo hoàn chỉnh: [supabase/schema.sql](file:///d:/PTAPP/PTUDDD_K65/supabase/schema.sql).

### Bảng 1: `public.profiles` (Người dùng)
| Trường | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY, REFERENCES auth.users(id)` | ID người dùng |
| `email` | `TEXT` | `NOT NULL, UNIQUE` | Email đăng nhập |
| `display_name` | `TEXT` | | Tên hiển thị |
| `avatar_url` | `TEXT` | | Ảnh đại diện |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Ngày tạo |
| `updated_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Ngày cập nhật |

### Bảng 2: `public.documents` (Tài liệu học tập)
| Trường | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Mã tài liệu |
| `owner_id` | `UUID` | `REFERENCES profiles(id) ON DELETE CASCADE` | Người sở hữu |
| `course_id` | `TEXT` | `NOT NULL` | Mã môn học |
| `title` | `TEXT` | `NOT NULL` | Tiêu đề tài liệu |
| `description` | `TEXT` | | Mô tả / Ghi chú |
| `document_type` | `TEXT` | `DEFAULT 'other'` | slide, exam, notes, ... |
| `status` | `TEXT` | `DEFAULT 'pending'` | pending, in_progress, completed |
| `priority` | `TEXT` | `DEFAULT 'medium'` | low, medium, high, urgent |
| `file_url` | `TEXT` | | Link tải từ Firebase Storage |
| `storage_path` | `TEXT` | | Đường dẫn `documents/{userId}/{docId}/...` |
| `file_name` | `TEXT` | | Tên file gốc |
| `file_size` | `BIGINT` | | Dung lượng tệp (bytes) |
| `page_count` | `INTEGER` | | Số trang |
| `tags` | `TEXT[]` | | Danh sách thẻ phân loại |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Thời gian tạo |
| `updated_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Thời gian cập nhật |

### Bảng 3: `public.document_permissions` (Quyền chia sẻ)
| Trường | Kiểu dữ liệu | Ràng buộc | Ý nghĩa |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY DEFAULT gen_random_uuid()` | Mã quyền |
| `document_id` | `UUID` | `REFERENCES documents(id) ON DELETE CASCADE` | Tài liệu được chia sẻ |
| `grantee_id` | `UUID` | `REFERENCES profiles(id) ON DELETE CASCADE` | Người nhận quyền |
| `permission_level` | `TEXT` | `CHECK (permission_level IN ('viewer', 'editor'))` | Cấp độ quyền |
| `created_at` | `TIMESTAMPTZ` | `DEFAULT now()` | Ngày cấp quyền |
| *(Unique)* | | `UNIQUE(document_id, grantee_id)` | Mỗi người nhận 1 quyền duy nhất |

---

## 3. CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)

Tất cả bảng đều được kích hoạt `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`:

### Đối với Bảng `documents`:
1. **SELECT (Đọc)**: Cho phép đọc nếu là **chủ sở hữu** (`auth.uid() = owner_id`) HOẶC có bản ghi cấp quyền trong bảng `document_permissions`.
2. **INSERT (Tạo mới)**: Chỉ người dùng đã xác thực và là chủ sở hữu (`auth.uid() = owner_id`).
3. **UPDATE (Chỉnh sửa)**: Cho phép nếu là **chủ sở hữu** HOẶC người được cấp quyền có cấp độ `'editor'`.
4. **DELETE (Xóa)**: **CHỈ DUY NHẤT** chủ sở hữu tài liệu (`auth.uid() = owner_id`) mới được phép xóa.

### Đối với Bảng `document_permissions`:
1. **SELECT**: Chủ sở hữu tài liệu hoặc chính người được nhận quyền.
2. **INSERT & UPDATE**: **CHỈ** chủ sở hữu tài liệu mới có quyền chia sẻ hoặc đổi cấp quyền.
3. **DELETE**: Chủ sở hữu tài liệu có thể thu hồi quyền, hoặc người nhận quyền tự xóa quyền của chính mình.

---

## 4. HƯỚNG DẪN THỰC THI TRÊN SUPABASE DASHBOARD

1. Đăng nhập [Supabase Dashboard](https://supabase.com/dashboard) và tạo dự án mới.
2. Vào mục **SQL Editor** ở thanh menu bên trái.
3. Mở file [supabase/schema.sql](file:///d:/PTAPP/PTUDDD_K65/supabase/schema.sql), sao chép toàn bộ nội dung và dán vào SQL Editor, sau đó nhấn **Run**.
4. Vào **Project Settings** -> **API**, sao chép:
   - **Project URL**
   - **anon public key**
5. Mở file [lib/supabase_options.dart](file:///d:/PTAPP/PTUDDD_K65/lib/supabase_options.dart) và cập nhật hai giá trị tương ứng:
   ```dart
   static const String supabaseUrl = 'https://xyzcompany.supabase.co';
   static const String supabaseAnonKey = 'eyJh...';
   ```

---

## 5. CÁC TÍNH NĂNG ĐÃ TÍCH HỢP TRÊN GIAO DIỆN

1. **Tìm kiếm & Lọc đa tiêu chí ([DocumentListPage](file:///d:/PTAPP/PTUDDD_K65/lib/pages/document_list_page.dart))**:
   - Thanh tìm kiếm thời gian thực theo tiêu đề và mô tả.
   - Bộ lọc môn học, loại tài liệu, trạng thái học tập.
   - Thêm nút lọc **"Được chia sẻ"** để xem nhanh các tài liệu người khác đã chia sẻ cho bạn.

2. **Cập nhật thông tin tài liệu ([AddEditDocumentPage](file:///d:/PTAPP/PTUDDD_K65/lib/pages/add_edit_document_page.dart))**:
   - Chỉnh sửa thông tin môn học, tiến độ, hạn chót, thẻ tags, và bảo tồn liên kết Firebase Storage.

3. **Chia sẻ tài liệu cho người khác ([ShareDocumentDialog](file:///d:/PTAPP/PTUDDD_K65/lib/widgets/share_document_dialog.dart))**:
   - Đặt nút **Chia sẻ** trên AppBar màn hình Chi tiết tài liệu ([DocumentDetailPage](file:///d:/PTAPP/PTUDDD_K65/lib/pages/document_detail_page.dart)).
   - Nhập email người nhận và phân quyền: **Chỉ xem (Viewer)** hoặc **Chỉnh sửa (Editor)**.
   - Xem danh sách người đang có quyền truy cập và nút **Gỡ quyền (Revoke)** nhanh chóng.
