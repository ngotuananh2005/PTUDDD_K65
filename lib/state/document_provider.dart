import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';
import '../services/document_calculator.dart';
import '../services/supabase_service.dart';

/// Provider điều phối trạng thái Quản lý Tài liệu Học tập
/// Kết nối Tầng Giao diện (UI) với Tầng Truy cập Dữ liệu (Database DAO)
/// Hỗ trợ cả tài liệu Local (SQLite) và Cloud (Supabase - tài liệu được chia sẻ)
class DocumentProvider extends ChangeNotifier {
  final StudyAppDatabase _database;
  final SupabaseService _supabaseService = SupabaseService();

  StreamSubscription<List<DocumentModel>>? _docsSubscription;
  StreamSubscription<List<CourseModel>>? _coursesSubscription;

  List<DocumentModel> _allDocuments = [];
  List<DocumentModel> _sharedDocuments = []; // Tài liệu người khác chia sẻ cho mình
  List<CourseModel> _allCourses = [];

  // Trạng thái tìm kiếm và bộ lọc đang áp dụng
  String _searchQuery = '';
  String _selectedCourseId = 'all'; // 'all' hoặc courseId cụ thể
  DocumentType? _selectedType; // null nghĩa là Tất cả
  StudyStatus? _selectedStatus; // null nghĩa là Tất cả
  bool _onlyShared = false; // Chỉ hiển thị tài liệu được người khác chia sẻ

  bool _isLoading = true;
  bool _isLoadingCloud = false;
  String? _currentUserId; // Firebase UID của người dùng hiện tại

  DocumentProvider({StudyAppDatabase? database})
      : _database = database ?? StudyAppDatabase() {
    _initSubscriptions();
  }

  // ==========================================
  // GETTERS
  // ==========================================

  bool get isLoading => _isLoading;
  bool get isLoadingCloud => _isLoadingCloud;
  String get searchQuery => _searchQuery;
  String get selectedCourseId => _selectedCourseId;
  DocumentType? get selectedType => _selectedType;
  StudyStatus? get selectedStatus => _selectedStatus;
  bool get onlyShared => _onlyShared;

  List<CourseModel> get courses => _allCourses;
  List<DocumentModel> get allDocuments => _allDocuments;
  List<DocumentModel> get sharedDocuments => _sharedDocuments;

  /// Tất cả tài liệu: local + được chia sẻ (gộp, loại trùng)
  List<DocumentModel> get allDocumentsWithShared {
    final localIds = _allDocuments.map((d) => d.id).toSet();
    final newShared = _sharedDocuments.where((d) => !localIds.contains(d.id));
    return [..._allDocuments, ...newShared];
  }

  /// Danh sách tài liệu sau khi đã lọc và tìm kiếm theo tiêu chí hiện tại
  List<DocumentModel> get filteredDocuments {
    // Nếu đang xem "Được chia sẻ" → dùng sharedDocuments
    if (_onlyShared) {
      var list = _sharedDocuments.where((d) {
        final matchQ = _searchQuery.isEmpty ||
            d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            d.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchCourse = _selectedCourseId == 'all' || d.courseId == _selectedCourseId;
        final matchType = _selectedType == null || d.type == _selectedType;
        final matchStatus = _selectedStatus == null || d.status == _selectedStatus;
        return matchQ && matchCourse && matchType && matchStatus;
      }).toList();
      return list;
    }

    // Mặc định: tài liệu local
    return _database.searchAndFilterDocuments(
      query: _searchQuery,
      courseId: _selectedCourseId,
      type: _selectedType,
      status: _selectedStatus,
    );
  }

  /// Số tài liệu được chia sẻ cho mình
  int get sharedCount => _sharedDocuments.length;

  /// Danh sách tài liệu được ghim / đánh dấu sao yêu thích
  List<DocumentModel> get pinnedDocuments {
    return _allDocuments.where((d) => d.isPinned).toList();
  }

  /// Thống kê tổng quan học tập
  StudyOverviewStatistics get overviewStats {
    return DocumentCalculator.calculateOverview(_allDocuments);
  }

  /// Thống kê tiến độ theo môn học
  List<CourseStudyProgress> get courseProgressList {
    return DocumentCalculator.calculateProgressByCourses(
      courses: _allCourses,
      documents: _allDocuments,
    );
  }

  /// Bản đồ phân bố theo loại tài liệu
  Map<DocumentType, int> get typeDistribution {
    return DocumentCalculator.getDistributionByType(_allDocuments);
  }

  CourseModel? getCourse(String courseId) {
    return _database.getCourseById(courseId);
  }

  // ==========================================
  // LẮNG NGHE REACTIVE STREAMS TỪ DATABASE
  // ==========================================

  void _initSubscriptions() {
    _docsSubscription = _database.watchAllDocuments().listen((docs) {
      _allDocuments = docs;
      _isLoading = false;
      notifyListeners();
    });

    _coursesSubscription = _database.watchAllCourses().listen((courses) {
      _allCourses = courses;
      notifyListeners();
    });
  }

  /// Được gọi khi người dùng đăng nhập/đăng xuất
  /// Tải tài liệu được chia sẻ từ Supabase
  Future<void> onUserChanged(String? userId) async {
    _currentUserId = userId;
    if (userId != null) {
      await loadSharedDocuments(userId: userId);
    } else {
      _sharedDocuments = [];
      notifyListeners();
    }
  }

  /// Tải danh sách tài liệu được người khác chia sẻ cho mình từ Supabase
  Future<void> loadSharedDocuments({required String userId}) async {
    _isLoadingCloud = true;
    notifyListeners();

    try {
      // Tìm tất cả tài liệu mà user này là grantee (người được chia sẻ)
      final docs = await _supabaseService.getSharedWithMe(userId: userId);
      _sharedDocuments = docs;
      debugPrint('Đã tải ${docs.length} tài liệu được chia sẻ từ Supabase');
    } catch (e) {
      debugPrint('Lỗi loadSharedDocuments: $e');
    } finally {
      _isLoadingCloud = false;
      notifyListeners();
    }
  }

  /// Refresh tài liệu được chia sẻ (kéo để làm mới)
  Future<void> refreshSharedDocuments() async {
    if (_currentUserId != null) {
      await loadSharedDocuments(userId: _currentUserId!);
    }
  }

  // ==========================================
  // CÁC HÀM CẬP NHẬT BỘ LỌC VÀ TÌM KIẾM
  // ==========================================

  void setSearchQuery(String query) {
    if (_searchQuery != query) {
      _searchQuery = query;
      notifyListeners();
    }
  }

  void setSelectedCourse(String courseId) {
    if (_selectedCourseId != courseId) {
      _selectedCourseId = courseId;
      notifyListeners();
    }
  }

  void setSelectedType(DocumentType? type) {
    if (_selectedType != type) {
      _selectedType = type;
      notifyListeners();
    }
  }

  void setSelectedStatus(StudyStatus? status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }

  void setOnlyShared(bool value) {
    if (_onlyShared != value) {
      _onlyShared = value;
      // Khi bật filter "Được chia sẻ", tự động load lại từ Supabase
      if (value && _currentUserId != null) {
        loadSharedDocuments(userId: _currentUserId!);
      }
      notifyListeners();
    }
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedCourseId = 'all';
    _selectedType = null;
    _selectedStatus = null;
    _onlyShared = false;
    notifyListeners();
  }

  // ==========================================
  // THAO TÁC NGHIỆP VỤ (CRUD FORWARDING TO DATABASE)
  // ==========================================

  /// Thêm hoặc sửa tài liệu
  Future<void> saveDocument(DocumentModel document) async {
    await _database.createOrUpdateDocument(document);
  }

  /// Xóa tài liệu
  Future<bool> deleteDocument(String id) async {
    return await _database.deleteDocument(id);
  }

  /// Bật/Tắt ghim
  Future<void> togglePin(String id) async {
    await _database.togglePinDocument(id);
  }

  /// Cập nhật nhanh trạng thái
  Future<void> updateStatus(String id, StudyStatus status) async {
    await _database.updateDocumentStatus(id, status);
  }

  /// Thêm hoặc sửa môn học
  Future<void> saveCourse(CourseModel course) async {
    await _database.createOrUpdateCourse(course);
  }

  /// Xóa môn học
  Future<void> deleteCourse(String courseId) async {
    await _database.deleteCourse(courseId);
    if (_selectedCourseId == courseId) {
      _selectedCourseId = 'all';
    }
  }

  /// Khôi phục dữ liệu ban đầu
  Future<void> resetData() async {
    _isLoading = true;
    notifyListeners();
    await _database.resetToDefault();
    resetFilters();
  }

  @override
  void dispose() {
    _docsSubscription?.cancel();
    _coursesSubscription?.cancel();
    super.dispose();
  }
}
