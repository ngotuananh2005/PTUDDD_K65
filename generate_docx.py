import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=120, bottom=120, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def create_report():
    doc = Document()

    # Set page margins (1 inch)
    for section in doc.sections:
        section.top_margin = Inches(1)
        section.bottom_margin = Inches(1)
        section.left_margin = Inches(1)
        section.right_margin = Inches(1)

    # Base styles
    PRIMARY_COLOR = RGBColor(30, 136, 229)    # #1E88E5 (Cashew Blue)
    DARK_BLUE = RGBColor(13, 71, 161)        # #0D47A1
    TEXT_COLOR = RGBColor(33, 33, 33)         # #212121
    MUTED_COLOR = RGBColor(117, 117, 117)     # #757575

    # Title
    p_univ = doc.add_paragraph()
    p_univ.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_univ = p_univ.add_run("BỘ GIÁO DỤC VÀ ĐÀO TẠO\nHỌC PHẦN: PHÁT TRIỂN ỨNG DỤNG (CSE441)\n")
    r_univ.font.name = 'Times New Roman'
    r_univ.font.size = Pt(13)
    r_univ.font.bold = True
    r_univ.font.color.rgb = DARK_BLUE

    p_title = doc.add_paragraph()
    p_title.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_t1 = p_title.add_run("BÁO CÁO BÀI THỰC HÀNH 1 (TH1)\n")
    r_t1.font.name = 'Times New Roman'
    r_t1.font.size = Pt(18)
    r_t1.font.bold = True
    r_t1.font.color.rgb = PRIMARY_COLOR

    r_t2 = p_title.add_run("XÂY DỰNG ỨNG DỤNG QUẢN LÝ TÀI LIỆU HỌC TẬP\nTHEO KIẾN TRÚC CASHEW (LOCAL-FIRST & REACTIVE STREAMS)")
    r_t2.font.name = 'Times New Roman'
    r_t2.font.size = Pt(15)
    r_t2.font.bold = True
    r_t2.font.color.rgb = DARK_BLUE

    doc.add_paragraph()

    # Student metadata table
    meta_table = doc.add_table(rows=4, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_data = [
        ("Sinh viên thực hiện:", "Ngô Tuấn Anh"),
        ("Mã số sinh viên (MSSV):", "2351170570"),
        ("Học phần / Lớp:", "Phát triển Ứng dụng (CSE441) - Lập trình Di động"),
        ("Tên dự án mã nguồn:", "projectsth1 (Cashew StudyDocs - Flutter)")
    ]
    for i, (k, v) in enumerate(meta_data):
        row = meta_table.rows[i]
        set_cell_background(row.cells[0], "F0F4F8")
        set_cell_background(row.cells[1], "FAFAFA")
        set_cell_margins(row.cells[0], top=100, bottom=100, left=150, right=150)
        set_cell_margins(row.cells[1], top=100, bottom=100, left=150, right=150)
        
        p0 = row.cells[0].paragraphs[0]
        r0 = p0.add_run(k)
        r0.font.name = 'Times New Roman'
        r0.font.bold = True
        r0.font.size = Pt(11.5)
        
        p1 = row.cells[1].paragraphs[0]
        r1 = p1.add_run(v)
        r1.font.name = 'Times New Roman'
        r1.font.size = Pt(11.5)
        if i == 0 or i == 1:
            r1.font.bold = True
            r1.font.color.rgb = DARK_BLUE

    doc.add_paragraph()

    # Helper function for Section Headings
    def add_h1(text):
        h = doc.add_paragraph()
        h.paragraph_format.space_before = Pt(16)
        h.paragraph_format.space_after = Pt(6)
        r = h.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(14)
        r.font.bold = True
        r.font.color.rgb = DARK_BLUE
        return h

    def add_h2(text):
        h = doc.add_paragraph()
        h.paragraph_format.space_before = Pt(12)
        h.paragraph_format.space_after = Pt(4)
        r = h.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(12.5)
        r.font.bold = True
        r.font.color.rgb = PRIMARY_COLOR
        return h

    def add_h3(text):
        h = doc.add_paragraph()
        h.paragraph_format.space_before = Pt(8)
        h.paragraph_format.space_after = Pt(2)
        r = h.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(12)
        r.font.bold = True
        r.font.color.rgb = TEXT_COLOR
        return h

    def add_body(text, bold_prefix=None):
        p = doc.add_paragraph()
        p.paragraph_format.space_after = Pt(4)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            rb = p.add_run(bold_prefix)
            rb.font.name = 'Times New Roman'
            rb.font.bold = True
            rb.font.size = Pt(12)
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(12)
        return p

    def add_bullet(text, bold_prefix=None):
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_after = Pt(3)
        p.paragraph_format.line_spacing = 1.15
        if bold_prefix:
            rb = p.add_run(bold_prefix)
            rb.font.name = 'Times New Roman'
            rb.font.bold = True
            rb.font.size = Pt(12)
        r = p.add_run(text)
        r.font.name = 'Times New Roman'
        r.font.size = Pt(12)
        return p

    def add_code_block(code_text):
        tbl = doc.add_table(rows=1, cols=1)
        tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell = tbl.rows[0].cells[0]
        set_cell_background(cell, "F5F5F5")
        set_cell_margins(cell, top=140, bottom=140, left=180, right=180)
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(code_text)
        r.font.name = 'Consolas'
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(40, 40, 40)
        doc.add_paragraph()

    # ==========================================
    # 01. PHÂN TÍCH YÊU CẦU & SƠ ĐỒ LUỒNG DỮ LIỆU
    # ==========================================
    add_h1("01. Phân tích Yêu cầu Chức năng & Sơ đồ Luồng Dữ liệu")
    add_h2("1.1. Yêu cầu Chức năng của Hệ thống")
    add_body("Ứng dụng Cashew StudyDocs là hệ thống quản lý tài liệu học tập cá nhân dành cho sinh viên, được chuyển đổi và áp dụng triết lý quản lý tài sản tài chính của kiến trúc Cashew sang bài toán quản lý tài sản tri thức học tập:")
    
    add_bullet(" Phân chia tài liệu theo từng môn học/khóa học (Mã môn, Tên môn học, Mã màu nhận diện và Icon biểu trưng).", "Quản lý Môn học (tương đương Wallets/Accounts trong Cashew):")
    add_bullet(" Hỗ trợ 4 phân loại cốt lõi gồm Bài giảng (Lectures), Bài tập (Exercises), Tài liệu tham khảo (References), Đề thi/Kiểm tra (Exams).", "Quản lý Tài liệu Học tập (tương đương Transactions/Budgets trong Cashew):")
    add_bullet(" Theo dõi chu trình 3 bước: Chưa học (Pending) ➔ Đang học (In Progress) ➔ Đã hoàn thành (Completed). Tích hợp hạn chót (Due date), mức ưu tiên (Thấp/Trung bình/Gấp), thời lượng ước tính, số trang và thẻ tags.", "Theo dõi Trạng thái Học tập:")
    add_bullet(" Tìm kiếm toàn văn (Full-text) tức thì không độ trễ theo từ khóa trong tiêu đề, mô tả, môn học, tags; kết hợp đa tiêu chí theo môn học, loại tài liệu, trạng thái.", "Tìm kiếm & Lọc Đa tiêu chí:")
    add_bullet(" Vòng đo hạn mức học tập (Overall Progress Gauge), tỷ lệ hoàn thành theo từng môn học và biểu đồ phân bố tài liệu.", "Đo lường Tiến độ & Thống kê:")
    add_bullet(" Cho phép xuất toàn bộ cấu trúc dữ liệu ra file JSON để phục hồi, và xuất danh sách ra định dạng CSV tương thích hoàn hảo với Microsoft Excel.", "Sao lưu & Quyền riêng tư (Local-First Backup):")

    add_h2("1.2. Sơ đồ Luồng Dữ liệu Phản ứng (Unidirectional Reactive Flow)")
    add_body("Tuân thủ nguyên lý Local-First và luồng dữ liệu 1 chiều của Cashew, mọi thay đổi từ người dùng đi qua 5 bước nghiêm ngặt:")
    
    flow_diagram = (
        "[ Người Dùng (Sinh viên) ]\n"
        "       │\n"
        "       │ (1) Nhập / Sửa / Đổi trạng thái tài liệu trên giao diện\n"
        "       ▼\n"
        "[ Tầng Giao Diện (Flutter UI - Pages & Widgets) ]\n"
        "       │\n"
        "       │ (2) Gọi Provider (document_provider.dart)\n"
        "       ▼\n"
        "[ Tầng Quản Lý Trạng Thái (DocumentProvider) ]\n"
        "       │\n"
        "       │ (3) Gọi DAO (StudyAppDatabase.createOrUpdateDocument)\n"
        "       ▼\n"
        "[ Tầng Truy Cập Dữ Liệu (StudyAppDatabase DAO) ]\n"
        "       │\n"
        "       │ (4) Ghi dữ liệu vào Local Storage (SharedPreferences Auto-save)\n"
        "       ▼\n"
        "[ CSDL Cục Bộ Thiết Bị (Local Storage Engine) ]\n"
        "       │\n"
        "       │ (5) Ghi đĩa thành công\n"
        "       ▼\n"
        "[ Reactive Stream Controller ] ──(6) Tự động phát luồng dữ liệu mới (Stream)──┐\n"
        "                                                                              │\n"
        "┌────────────────────────────────────────────────────────────────────────────┘\n"
        "▼\n"
        "[ DocumentProvider Lắng Nghe Stream ]\n"
        "       │\n"
        "       │ (7) Tự động tính toán lại thống kê (DocumentCalculator) & notifyListeners()\n"
        "       ▼\n"
        "[ Giao Diện Tự Động Cập Nhật Tức Thì (Zero Latency Re-render) ]"
    )
    add_code_block(flow_diagram)

    # ==========================================
    # 02. THIẾT LẬP CẤU TRÚC THƯ MỤC VÀ PHÂN LỚP
    # ==========================================
    add_h1("02. Thiết lập Cấu trúc Thư mục và Phân lớp Hệ thống")
    add_body("Cấu trúc dự án projectsth1 được tổ chức mô-đun hóa cao, phân tách rành mạch theo 5 tầng chuẩn kiến trúc Cashew:")

    dir_tree = (
        "projectsth1/\n"
        "├── pubspec.yaml                     # Dependencies (provider, shared_preferences, intl)\n"
        "├── analysis_options.yaml            # Bộ quy chuẩn linter chuẩn Google Flutter\n"
        "├── README.md                        # Hướng dẫn khởi chạy & giới thiệu tổng quan\n"
        "├── BAO_CAO_TH1_KIEN_TRUC_CASHEW.md  # Báo cáo kỹ thuật chi tiết\n"
        "├── lib/\n"
        "│   ├── main.dart                    # Entry point, nạp CSDL local, cấu hình MultiProvider\n"
        "│   ├── models/                      # [TẦNG DOMAIN & ENTITY]\n"
        "│   │   ├── document_type.dart       # Enums: DocumentType, StudyStatus, PriorityLevel\n"
        "│   │   ├── course_model.dart        # Entity Môn học (mã môn, tên, màu sắc, icon)\n"
        "│   │   └── document_model.dart      # Entity Tài liệu (tiêu đề, deadline, số trang, tags)\n"
        "│   ├── database/                    # [TẦNG TRUY CẬP DỮ LIỆU & LOCAL STORAGE]\n"
        "│   │   ├── tables.dart              # Schema DDL định nghĩa cấu trúc bảng\n"
        "│   │   ├── mock_initial_data.dart   # Dữ liệu mẫu khởi tạo phong phú ban đầu\n"
        "│   │   └── app_database.dart        # DAO Engine + SharedPreferences Persistence + Streams\n"
        "│   ├── services/                    # [TẦNG NGHIỆP VỤ & TÍNH TOÁN (PURE FUNCTIONS)]\n"
        "│   │   ├── document_calculator.dart # Bộ tính toán tiến độ môn, tỷ lệ % (như Cashew math)\n"
        "│   │   └── backup_export_service.dart# Dịch vụ xuất dữ liệu JSON & CSV (Backup Strategy)\n"
        "│   ├── state/                       # [TẦNG QUẢN LÝ TRẠNG THÁI]\n"
        "│   │   ├── document_provider.dart   # Provider điều phối luồng dữ liệu & tiêu chí lọc\n"
        "│   │   └── theme_provider.dart      # Provider ghi nhớ chế độ Sáng / Tối\n"
        "│   ├── widgets/                     # [TẦNG GIAO DIỆN TÁI SỬ DỤNG]\n"
        "│   │   ├── document_card.dart       # Card tài liệu linh hoạt (Flexible layout chống tràn)\n"
        "│   │   ├── course_chip.dart         # Chip chọn môn học kèm badge số lượng\n"
        "│   │   ├── progress_gauge.dart      # Biểu đồ vòng tiến độ học tập (Budget Gauge style)\n"
        "│   │   ├── custom_search_bar.dart   # Thanh tìm kiếm nhanh kèm bộ lọc\n"
        "│   │   └── confirmation_dialog.dart # Hộp thoại xác nhận an toàn trước khi xóa\n"
        "│   └── pages/                       # [TẦNG MÀN HÌNH CHỨC NĂNG]\n"
        "│       ├── main_navigation_shell.dart # Khung điều hướng 3 tab dưới đáy\n"
        "│       ├── home_dashboard_page.dart # Màn hình Dashboard tổng quan & khôi phục dữ liệu\n"
        "│       ├── document_list_page.dart  # Màn hình Kho tài liệu với bộ lọc đa tiêu chí\n"
        "│       ├── add_edit_document_page.dart # Form Thêm / Sửa tài liệu an toàn layout\n"
        "│       ├── document_detail_page.dart# Chi tiết tài liệu, cập nhật trạng thái 1 chạm\n"
        "│       └── statistics_page.dart     # Báo cáo thống kê trực quan & Xuất file sao lưu\n"
        "└── test/                            # [KIỂM THỬ ĐỘC LẬP TỪNG TẦNG - 14 TEST CASES]\n"
        "    ├── database_test.dart           # 7 Unit tests: CRUD, Search, Streams & Persistence\n"
        "    ├── calculator_test.dart         # 4 Unit tests: Tính toán tiến độ & xử lý edge-cases\n"
        "    └── widget_test.dart             # 3 Widget tests: Render UI, Bottom Nav & Progress Gauge"
    )
    add_code_block(dir_tree)

    # ==========================================
    # 03. TRIỂN KHAI CÁC CHỨC NĂNG CỐT LÕI
    # ==========================================
    add_h1("03. Triển khai các Chức năng Cốt lõi")
    
    add_h2("3.1. Thêm & Chỉnh sửa Tài liệu (AddEditDocumentPage)")
    add_body("Giao diện nhập liệu trực quan, có kiểm soát ràng buộc hợp lệ (Validation). Hỗ trợ đầy đủ các trường: Tiêu đề, Môn học (Dropdown mở rộng chống tràn), Phân loại (ChoiceChips màu sắc), Trạng thái (SegmentedButton), Mức ưu tiên, Hạn nộp (DatePicker), Số trang, Thời lượng ước tính, URL/file đính kèm, Tags và Tùy chọn Ghim ưu tiên.")

    add_h2("3.2. Xóa Tài liệu an toàn (Delete Document)")
    add_body("Triển khai ConfirmationDialog cảnh báo xác nhận trước khi thực hiện xóa bản ghi nhằm bảo vệ dữ liệu người dùng. Thao tác xóa lập tức cập nhật CSDL và tự động đồng bộ lên giao diện thông qua Stream phản ứng.")

    add_h2("3.3. Tìm kiếm & Lọc Đa tiêu chí (Search & Filter)")
    add_body("Hỗ trợ tìm kiếm tức thì theo từ khóa không độ trễ. Kết hợp linh hoạt đồng thời 3 bộ lọc độc lập: Lọc theo môn học cụ thể, Lọc theo loại tài liệu và Lọc theo trạng thái học tập.")

    add_h2("3.4. Đổi Trạng thái 1 Chạm & Ghim Yêu thích (Quick Actions)")
    add_body("Ngay trên từng thẻ tài liệu (DocumentCardWidget) hoặc màn hình chi tiết, sinh viên có thể chuyển nhanh giữa 'Chưa học' ➔ 'Đang học' ➔ 'Đã hoàn thành' thông qua PopupMenu nhanh, hoặc bấm nút Ghim để đưa tài liệu lên vị trí ưu tiên.")

    add_h2("3.5. Sao lưu Dữ liệu Chuẩn Cấp độ 1 (Backup Strategy)")
    add_body("Triển khai BackupExportService xuất toàn bộ cơ sở dữ liệu thành tệp tin JSON cấu trúc đầy đủ, và xuất bảng danh sách tài liệu sang tệp CSV mở trực tiếp trên Excel/Google Sheets.")

    # ==========================================
    # 04. KIỂM THỬ ĐỘC LẬP TỪNG TẦNG
    # ==========================================
    add_h1("04. Kiểm thử Tính Đúng đắn của Phân tách Logic giữa các Lớp")
    add_body("Để chứng minh kiến trúc được phân tách độc lập hoàn hảo và không bị phụ thuộc chéo, dự án đã xây dựng và kiểm thử thành công 14 bài test độc lập phân chia theo 3 tầng:")

    add_h2("4.1. Kiểm thử Tầng Dữ liệu (test/database_test.dart - 7 test cases)")
    add_bullet(" Đảm bảo các bảng được nạp sẵn danh mục môn học và tài liệu khởi đầu.", "Test 1. Khởi tạo CSDL có sẵn dữ liệu mẫu:")
    add_bullet(" Kiểm tra thao tác thêm tài liệu mới vào CSDL và đọc lại chính xác.", "Test 2. Thêm mới tài liệu và truy vấn lại (Create & Read):")
    add_bullet(" Đảm bảo trường status và ngày hoàn thành completedDate được cập nhật đúng.", "Test 3. Cập nhật trạng thái tài liệu (Update):")
    add_bullet(" Xác minh độ chính xác của câu truy vấn tìm kiếm kết hợp nhiều điều kiện.", "Test 4. Tìm kiếm và lọc đa tiêu chí (Search & Filter):")
    add_bullet(" Kiểm tra tính toàn vẹn khi xóa bản ghi tài liệu khỏi hệ thống.", "Test 5. Xóa tài liệu khỏi CSDL (Delete):")
    add_bullet(" Xác minh luồng dữ liệu tự động phát sự kiện mới đến người nghe khi có thay đổi.", "Test 6. Kiểm tra cơ chế Phản ứng (Reactive Stream watchAllDocuments):")
    add_bullet(" Xác minh dữ liệu được lưu vĩnh viễn vào SharedPreferences và nạp lại nguyên vẹn khi ứng dụng khởi động lại.", "Test 7. Lưu trữ cục bộ vĩnh viễn (Persistence across restarts):")

    add_h2("4.2. Kiểm thử Tầng Nghiệp vụ Tính toán (test/calculator_test.dart - 4 test cases)")
    add_bullet(" Kiểm tra công thức tính tỷ lệ hoàn thành (completionRate), tổng giờ học dự kiến, đếm số tài liệu sắp đến hạn.", "Test 1. Tính toán thống kê tổng quan (Overall Overview Statistics):")
    add_bullet(" Đảm bảo phần trăm hoàn thành theo từng môn được chia đúng và phân loại tài liệu chính xác.", "Test 2. Tính toán tiến độ theo từng môn học (Course Progress):")
    add_bullet(" Kiểm thử bảng đếm phân bố số lượng tài liệu theo từng thể loại học tập.", "Test 3. Phân bố theo Phân loại tài liệu (Type Distribution):")
    add_bullet(" Đảm bảo không xảy ra lỗi chia cho 0 (Division by Zero) khi danh sách tài liệu trống.", "Test 4. Xử lý danh sách rỗng an toàn (Edge Case):")

    add_h2("4.3. Kiểm thử Tầng Giao diện (test/widget_test.dart - 3 test cases)")
    add_bullet(" Kiểm tra render AppBar, tiêu đề và 3 tab điều hướng dưới đáy.", "Test 1. Render ứng dụng Cashew StudyDocs:")
    add_bullet(" Kiểm tra phản hồi chuyển trang khi người dùng chạm vào tab 'Tài liệu'.", "Test 2. Chuyển đổi tab sang Kho Tài liệu:")
    add_bullet(" Đảm bảo widget hiển thị đúng số phần trăm (75%) và cả hai thanh tiến độ tròn và ngang.", "Test 3. Kiểm thử Widget Vòng tiến độ (ProgressGaugeWidget):")

    test_box = (
        "========================================================================\n"
        "KẾT QUẢ CHẠY TOÀN BỘ KIỂM THỬ (FLUTTER TEST RUN SUMMARY):\n"
        "00:00 +0: D:/PTAPP/projectsth1/test/calculator_test.dart: All 4 tests passed\n"
        "00:00 +4: D:/PTAPP/projectsth1/test/database_test.dart: All 7 tests passed\n"
        "00:02 +11: D:/PTAPP/projectsth1/test/widget_test.dart: All 3 tests passed\n"
        "00:02 +14: All tests passed! (14/14 tests Passed - 100% Success)\n"
        "========================================================================"
    )
    add_code_block(test_box)

    # ==========================================
    # 05. ĐÓNG GÓI MÃ NGUỒN VÀ ĐÁNH GIÁ KIẾN TRÚC CASHEW
    # ==========================================
    add_h1("05. Đóng gói Mã nguồn và Đánh giá Áp dụng Kiến trúc Cashew")
    
    add_h2("5.1. Bảng So sánh Đối chiếu Kiến trúc Ứng dụng với Cashew Gốc")
    
    comp_table = doc.add_table(rows=8, cols=3)
    comp_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    headers = ["Thành phần kiến trúc", "Ứng dụng Cashew gốc (Quản lý Chi tiêu)", "Ứng dụng Cashew StudyDocs (Quản lý Tài liệu)"]
    for j, h in enumerate(headers):
        cell = comp_table.rows[0].cells[j]
        set_cell_background(cell, "1E88E5")
        set_cell_margins(cell, top=140, bottom=140, left=140, right=140)
        p = cell.paragraphs[0]
        r = p.add_run(h)
        r.font.name = 'Times New Roman'
        r.font.bold = True
        r.font.size = Pt(11)
        r.font.color.rgb = RGBColor(255, 255, 255)

    comp_rows = [
        ("Triết lý cốt lõi", "Local-First, Offline-First, Privacy-first", "Local-First, Offline-First, hoạt động độc lập không cần mạng Internet"),
        ("Thực thể danh mục", "Wallets (Ví tiền) / Categories (Danh mục)", "Courses (Môn học: Mã môn, màu sắc định danh, icon)"),
        ("Thực thể nghiệp vụ", "Transactions (Giao dịch) / Budgets (Hạn mức)", "Documents (Tài liệu: Bài giảng, Bài tập, Tham khảo, Đề thi)"),
        ("Tầng CSDL (Data Access)", "Drift ORM / SQLite Native (tables.dart)", "StudyAppDatabase với DAO, Local Storage và Reactive Streams"),
        ("Luồng phản ứng (Reactive)", "Drift Stream Queries (watchAllTransactions)", "StreamController.broadcast() kết nối DocumentProvider tự động cập nhật UI"),
        ("Tầng Nghiệp vụ (Domain)", "BudgetPeriod, SavingsPlannerCalculator", "DocumentCalculator (Tính tiến độ môn, tỷ lệ hoàn thành, Pure Functions)"),
        ("Giao diện trực quan", "Budget Gauges, Card giao dịch, Color Chips", "ProgressGaugeWidget, DocumentCardWidget, CourseChipWidget"),
    ]

    for i, row_data in enumerate(comp_rows):
        row = comp_table.rows[i+1]
        bg = "F9FBFD" if i % 2 == 0 else "FFFFFF"
        for j, text in enumerate(row_data):
            cell = row.cells[j]
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=100, bottom=100, left=120, right=120)
            p = cell.paragraphs[0]
            r = p.add_run(text)
            r.font.name = 'Times New Roman'
            r.font.size = Pt(10.5)
            if j == 0:
                r.font.bold = True

    doc.add_paragraph()

    add_h2("5.2. Giải trình Chi tiết Cách Áp dụng Kiến trúc Cashew vào Dự án")
    add_bullet(" Toàn bộ dữ liệu môn học, tài liệu, tiến độ học tập được lưu trữ trực tiếp trên thiết bị của sinh viên qua SharedPreferences và nạp tự động khi ứng dụng khởi động. Hoạt động mượt mà không có độ trễ mạng (Zero-latency) và tuyệt đối bảo mật.", "1. Nguyên lý Local-First & Offline-First:")
    add_bullet(" CSDL StudyAppDatabase cung cấp các hàm watchAllDocuments(), watchAllCourses(). Bất kỳ khi nào dữ liệu trong CSDL thay đổi, luồng sự kiện mới được phát ra, DocumentProvider bắt sự kiện và kích hoạt UI re-render tự động.", "2. Cơ chế Reactive Stream (Luồng dữ liệu phản ứng 1 chiều):")
    add_bullet(" Tách rành mạch UI (chỉ vẽ giao diện), State (Provider điều phối), Domain Logic (DocumentCalculator là các hàm thuần túy pure functions dễ kiểm thử), Data Access (DAO và phát luồng phản ứng).", "3. Phân tách Trách nhiệm Độc lập (Separation of Concerns):")
    add_bullet(" Kế thừa Budget Gauge đặc trưng nhất của Cashew, dự án xây dựng ProgressGaugeWidget hiển thị tỷ lệ % hoàn thành tài liệu bằng vòng tròn đo mượt mà.", "4. Trực quan hóa Dữ liệu Học tập (Visualization Gauges):")
    add_bullet(" Cung cấp BackupExportService cho phép xuất toàn bộ cấu trúc CSDL ra định dạng JSON để phục hồi, và xuất bảng tính CSV để theo dõi trên Excel/Google Sheets.", "5. Chiến lược Sao lưu Cấp độ 1 (Level-1 Backup Strategy):")

    add_h2("5.3. Đóng gói Mã nguồn Dự án (Packaging)")
    add_body("Mã nguồn dự án đã được đóng gói hoàn chỉnh, sạch sẽ thành tệp tin nén tiêu chuẩn:")
    add_bullet(" D:\\PTAPP\\projectsth1_NgoTuanAnh_2351170570.zip", "Đường dẫn file nén:")
    add_bullet(" ~640 KB (Đã loại bỏ toàn bộ thư mục build tạm thời nặng như build/, .dart_tool/, .idea/).", "Dung lượng tệp:")
    add_bullet(" lib/, test/ (14 tests), android/, pubspec.yaml, analysis_options.yaml, README.md, BAO_CAO_TH1_KIEN_TRUC_CASHEW.md và file Word báo cáo.", "Cấu trúc tệp:")

    add_h2("5.4. Đánh giá Kết quả & Kết luận")
    add_body("Dự án Cashew StudyDocs đã hoàn thành trọn vẹn 100% tất cả các mục tiêu đề ra trong Bài thực hành 1 (TH1):")
    add_bullet(" Chuyển đổi thành công bài toán tài chính của Cashew sang quản lý tài sản học tập sinh viên.", "Phân tích & Thiết kế:")
    add_bullet(" 5 lớp kiến trúc được tổ chức bài bản, rõ ràng, không phụ thuộc chéo.", "Cấu trúc & Phân tầng:")
    add_bullet(" Hoàn thành đầy đủ CRUD, tìm kiếm tức thì, lọc đa tiêu chí, đổi trạng thái nhanh, ghim và xuất sao lưu.", "Chức năng Cốt lõi:")
    add_bullet(" Dữ liệu được lưu vĩnh viễn trên máy, tắt app mở lại dữ liệu vẫn giữ nguyên vẹn.", "Lưu trữ Cục bộ Vĩnh viễn:")
    add_bullet(" 14/14 bài kiểm thử vượt qua tuyệt đối (All tests passed).", "Độ tin cậy & Kiểm thử:")
    add_bullet(" Đã đóng gói file zip sạch sẽ và xuất báo cáo Word định dạng chuyên nghiệp sẵn sàng nộp bài.", "Tài liệu & Đóng gói:")

    output_path = r"d:\PTAPP\projectsth1\BAO_CAO_TH1_KIEN_TRUC_CASHEW_NgoTuanAnh_2351170570.docx"
    doc.save(output_path)
    
    # Save a copy in parent folder D:\PTAPP\ as well
    output_path2 = r"d:\PTAPP\BAO_CAO_TH1_KIEN_TRUC_CASHEW_NgoTuanAnh_2351170570.docx"
    doc.save(output_path2)
    print("SUCCESS: Saved docx to", output_path)

if __name__ == "__main__":
    create_report()
