import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/app_database.dart';
import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';
import '../services/document_calculator.dart';

/// Provider điều phối trạng thái Quản lý Tài liệu Học tập
/// Kết nối Tầng Giao diện (UI) với Tầng Truy cập Dữ liệu (Database DAO)
class DocumentProvider extends ChangeNotifier {
  final StudyAppDatabase _database;

  StreamSubscription<List<DocumentModel>>? _docsSubscription;
  StreamSubscription<List<CourseModel>>? _coursesSubscription;

  List<DocumentModel> _allDocuments = [];
  List<CourseModel> _allCourses = [];

  // Trạng thái tìm kiếm và bộ lọc đang áp dụng
  String _searchQuery = '';
  String _selectedCourseId = 'all'; // 'all' hoặc courseId cụ thể
  DocumentType? _selectedType; // null nghĩa là Tất cả
  StudyStatus? _selectedStatus; // null nghĩa là Tất cả

  bool _isLoading = true;

  DocumentProvider({StudyAppDatabase? database})
      : _database = database ?? StudyAppDatabase() {
    _initSubscriptions();
  }

  // ==========================================
  // GETTERS
  // ==========================================

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCourseId => _selectedCourseId;
  DocumentType? get selectedType => _selectedType;
  StudyStatus? get selectedStatus => _selectedStatus;

  List<CourseModel> get courses => _allCourses;
  List<DocumentModel> get allDocuments => _allDocuments;

  /// Danh sách tài liệu sau khi đã lọc và tìm kiếm theo tiêu chí hiện tại
  List<DocumentModel> get filteredDocuments {
    return _database.searchAndFilterDocuments(
      query: _searchQuery,
      courseId: _selectedCourseId,
      type: _selectedType,
      status: _selectedStatus,
    );
  }

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

  void resetFilters() {
    _searchQuery = '';
    _selectedCourseId = 'all';
    _selectedType = null;
    _selectedStatus = null;
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
