# 📚 Cashew StudyDocs - Ứng dụng Quản lý Tài liệu Học tập

Ứng dụng quản lý tài liệu học tập (bài giảng, bài tập, tài liệu tham khảo, đề thi) được thiết kế và xây dựng theo chuẩn **Kiến trúc Cashew (Local-First / Offline-First & Reactive Stream Architecture)**.

---

## 📌 Thông tin bài tập
- **Bài thực hành**: TH1 - Xây dựng Ứng dụng Quản lý Tài liệu Học tập theo Kiến trúc Cashew
- **Học phần**: Phát triển Ứng dụng (CSE441) - Lập trình Di động
- **Sinh viên thực hiện**: Ngô Tuấn Anh (MSSV: 2351170570)
- **Thư mục project**: `projectsth1/`

---

## 🏗️ Kiến trúc Hệ thống (Cashew Architecture)

Dự án áp dụng mô hình phân tách 5 lớp theo tiêu chuẩn của Cashew:

1. **Presentation Layer (Tầng Trình diễn / Giao diện)**:
   - `lib/pages/`: Các màn hình chính (`HomeDashboardPage`, `DocumentListPage`, `AddEditDocumentPage`, `DocumentDetailPage`, `StatisticsPage`).
   - `lib/widgets/`: Các thành phần giao diện tái sử dụng (`DocumentCardWidget`, `ProgressGaugeWidget`, `CourseChipWidget`, `CustomSearchBarWidget`, `ConfirmationDialog`).
2. **State Management (Tầng Quản lý Trạng thái)**:
   - `lib/state/document_provider.dart`: Sử dụng `Provider` kết hợp `ChangeNotifier` lắng nghe luồng dữ liệu phản ứng (**Reactive Streams**) từ CSDL.
   - `lib/state/theme_provider.dart`: Điều khiển chế độ Sáng / Tối (Light / Dark mode).
3. **Domain & Business Logic Layer (Tầng Nghiệp vụ & Tính toán)**:
   - `lib/services/document_calculator.dart`: Bộ tính toán tiến độ hoàn thành, thống kê theo môn học, thời lượng học tập.
   - `lib/services/backup_export_service.dart`: Chiến lược sao lưu cấp độ 1 (xuất JSON và CSV).
4. **Data Access / ORM Layer (Tầng Truy cập CSDL)**:
   - `lib/database/tables.dart`: Định nghĩa cấu trúc Schema các bảng.
   - `lib/database/app_database.dart`: Triển khai DAO, câu lệnh truy vấn type-safe và các Reactive Streams (`watchAllDocuments`, `watchAllCourses`, `watchPinnedDocuments`).
5. **Local Storage Layer (Tầng Lưu trữ Cục bộ)**:
   - Lưu trữ trực tiếp trên thiết bị (In-memory / SQLite Engine), hoàn toàn độc lập với mạng Internet.

---

## 🚀 Tính năng Cốt lõi
- ✅ **Thêm / Sửa / Xóa tài liệu**: Quản lý bài giảng, bài tập, tài liệu tham khảo, đề thi với đầy đủ thông tin (môn học, ngày hết hạn, thời lượng, số trang, link/file, mức độ ưu tiên).
- ✅ **Tìm kiếm & Lọc đa tiêu chí**: Tìm kiếm tức thì theo từ khóa, lọc theo môn học, theo loại tài liệu và theo trạng thái học tập.
- ✅ **Đánh dấu & Ghim yêu thích**: Ưu tiên hiển thị các tài liệu quan trọng trên đầu danh sách và Dashboard.
- ✅ **Đổi trạng thái học tập nhanh**: `Chưa học` ➔ `Đang học` ➔ `Đã hoàn thành`.
- ✅ **Báo cáo & Thống kê**: Biểu đồ tiến độ hoàn thành (Vòng tròn & Thanh tiến độ), phân bố tài liệu, thời gian học tập dự kiến.
- ✅ **Sao lưu dữ liệu (Backup)**: Xuất CSDL ra định dạng JSON và xuất danh sách ra bảng tính CSV tương thích Excel.
- ✅ **Giao diện Material 3 & Dark Mode**: Tự động thích ứng giao diện Sáng / Tối.

---

## 🧪 Kiểm thử Đơn vị & Widget (Test Suite)
Dự án bao gồm đầy đủ bài kiểm thử xác minh việc phân tách logic giữa các tầng:
- `test/database_test.dart`: Kiểm thử tầng CSDL (CRUD, Search, Reactive Streams).
- `test/calculator_test.dart`: Kiểm thử tầng Nghiệp vụ tính toán (Tiến độ môn học, tỷ lệ hoàn thành).
- `test/widget_test.dart`: Kiểm thử tầng Giao diện (Render Dashboard, chuyển tab, Widget tương tác).

Chạy toàn bộ test bằng lệnh:
```bash
flutter test
```

---

## 📖 Báo cáo Chi tiết
Báo cáo giải trình đầy đủ với sơ đồ kiến trúc tổng thể, sơ đồ tuần tự và luồng dữ liệu:
👉 **[BAO_CAO_TH1_KIEN_TRUC_CASHEW.md](./BAO_CAO_TH1_KIEN_TRUC_CASHEW.md)**
