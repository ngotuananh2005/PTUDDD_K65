import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../models/document_model.dart';
import '../models/document_type.dart';
import 'mock_initial_data.dart';

/// Database Engine & DAO Tầng Truy cập Dữ liệu
/// Áp dụng nguyên lý Local-First và Reactive Stream (Drift-like) của Cashew
class StudyAppDatabase {
  // Singleton Pattern
  static final StudyAppDatabase _instance = StudyAppDatabase._internal();
  factory StudyAppDatabase() => _instance;
  StudyAppDatabase._internal() {
    _initData();
  }

  static const String _coursesPrefKey = 'cashew_courses_v1';
  static const String _documentsPrefKey = 'cashew_documents_v1';

  SharedPreferences? _prefs;

  // Bộ lưu trữ dữ liệu cục bộ trong bộ nhớ (In-memory Local Storage Engine)
  final Map<String, CourseModel> _coursesMap = {};
  final Map<String, DocumentModel> _documentsMap = {};

  // Reactive Stream Controllers (Tương tự Drift Stream Queries trong Cashew)
  final StreamController<List<DocumentModel>> _documentsStreamController =
      StreamController<List<DocumentModel>>.broadcast();
  final StreamController<List<CourseModel>> _coursesStreamController =
      StreamController<List<CourseModel>>.broadcast();

  bool _isInitialized = false;

  void _initData() {
    if (_isInitialized) return;
    final initialCourses = MockInitialData.getInitialCourses();
    for (var c in initialCourses) {
      _coursesMap[c.courseId] = c;
    }

    final initialDocs = MockInitialData.getInitialDocuments();
    for (var d in initialDocs) {
      _documentsMap[d.id] = d;
    }

    _isInitialized = true;
    _notifyChanges();
  }

  /// Khởi tạo và nạp dữ liệu đã lưu từ bộ nhớ thiết bị (SharedPreferences)
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final coursesJson = _prefs!.getString(_coursesPrefKey);
      final docsJson = _prefs!.getString(_documentsPrefKey);

      if (coursesJson != null && docsJson != null) {
        final List<dynamic> decodedCourses = jsonDecode(coursesJson);
        final List<dynamic> decodedDocs = jsonDecode(docsJson);

        _coursesMap.clear();
        for (var c in decodedCourses) {
          final course = CourseModel.fromMap(Map<String, dynamic>.from(c as Map));
          _coursesMap[course.courseId] = course;
        }

        _documentsMap.clear();
        for (var d in decodedDocs) {
          final doc = DocumentModel.fromMap(Map<String, dynamic>.from(d as Map));
          _documentsMap[doc.id] = doc;
        }

        _isInitialized = true;
        _notifyChanges();
      } else {
        // Lần đầu tiên chạy ứng dụng: lưu bộ dữ liệu mẫu vào bộ nhớ
        await _saveToDisk();
      }
    } catch (e) {
      debugPrint('StudyAppDatabase.init error: $e');
    }
  }

  /// Lưu dữ liệu hiện tại vào bộ nhớ vĩnh viễn (Local Storage)
  Future<void> _saveToDisk() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final coursesList = _coursesMap.values.map((c) => c.toMap()).toList();
      final docsList = _documentsMap.values.map((d) => d.toMap()).toList();
      await _prefs!.setString(_coursesPrefKey, jsonEncode(coursesList));
      await _prefs!.setString(_documentsPrefKey, jsonEncode(docsList));
    } catch (e) {
      debugPrint('StudyAppDatabase._saveToDisk error: $e');
    }
  }

  /// Phát tín hiệu cập nhật tự động đến toàn bộ người nghe (Reactive Streams)
  void _notifyChanges() {
    final docs = getAllDocuments();
    final courses = getAllCourses();
    if (!_documentsStreamController.isClosed) {
      _documentsStreamController.add(docs);
    }
    if (!_coursesStreamController.isClosed) {
      _coursesStreamController.add(courses);
    }
  }

  // ==========================================
  // STREAMS (LẮNG NGHE THAY ĐỔI THEO THỜI GIAN THỰC)
  // ==========================================

  /// Lắng nghe toàn bộ danh sách tài liệu
  Stream<List<DocumentModel>> watchAllDocuments() async* {
    yield getAllDocuments();
    yield* _documentsStreamController.stream;
  }

  /// Lắng nghe danh sách môn học
  Stream<List<CourseModel>> watchAllCourses() async* {
    yield getAllCourses();
    yield* _coursesStreamController.stream;
  }

  /// Lắng nghe danh sách tài liệu được ghim (Favorite / Pinned)
  Stream<List<DocumentModel>> watchPinnedDocuments() async* {
    yield getAllDocuments().where((d) => d.isPinned).toList();
    yield* _documentsStreamController.stream
        .map((docs) => docs.where((d) => d.isPinned).toList());
  }

  // ==========================================
  // THAO TÁC TRUY VẤN (QUERY - READ OPERATIONS)
  // ==========================================

  /// Lấy toàn bộ tài liệu (sắp xếp ghim trước, sau đó theo ngày tạo mới nhất)
  List<DocumentModel> getAllDocuments() {
    final list = _documentsMap.values.toList();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.dateCreated.compareTo(a.dateCreated);
    });
    return list;
  }

  /// Lấy chi tiết 1 tài liệu theo ID
  DocumentModel? getDocumentById(String id) {
    return _documentsMap[id];
  }

  /// Lấy toàn bộ môn học
  List<CourseModel> getAllCourses() {
    final list = _coursesMap.values.toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  /// Lấy thông tin 1 môn học theo ID
  CourseModel? getCourseById(String courseId) {
    return _coursesMap[courseId];
  }

  /// Tìm kiếm và lọc tài liệu đa tiêu chí
  List<DocumentModel> searchAndFilterDocuments({
    String query = '',
    String? courseId,
    DocumentType? type,
    StudyStatus? status,
  }) {
    final cleanQuery = query.trim().toLowerCase();

    return getAllDocuments().where((doc) {
      // 1. Lọc theo từ khóa tìm kiếm (tiêu đề, mô tả, tags)
      if (cleanQuery.isNotEmpty) {
        final matchTitle = doc.title.toLowerCase().contains(cleanQuery);
        final matchDesc = doc.description.toLowerCase().contains(cleanQuery);
        final matchTags = doc.tags.any((t) => t.toLowerCase().contains(cleanQuery));
        final course = getCourseById(doc.courseId);
        final matchCourse = course != null &&
            (course.name.toLowerCase().contains(cleanQuery) ||
                course.code.toLowerCase().contains(cleanQuery));

        if (!matchTitle && !matchDesc && !matchTags && !matchCourse) {
          return false;
        }
      }

      // 2. Lọc theo môn học
      if (courseId != null && courseId.isNotEmpty && courseId != 'all') {
        if (doc.courseId != courseId) return false;
      }

      // 3. Lọc theo loại tài liệu
      if (type != null) {
        if (doc.type != type) return false;
      }

      // 4. Lọc theo trạng thái
      if (status != null) {
        if (doc.status != status) return false;
      }

      return true;
    }).toList();
  }

  // ==========================================
  // THAO TÁC THAY ĐỔI DỮ LIỆU (CUD OPERATIONS)
  // ==========================================

  /// Thêm hoặc Cập nhật Tài liệu (Create or Update Document)
  Future<void> createOrUpdateDocument(DocumentModel document) async {
    _documentsMap[document.id] = document;
    _notifyChanges();
    await _saveToDisk();
  }

  /// Xóa Tài liệu theo ID (Delete Document)
  Future<bool> deleteDocument(String id) async {
    if (_documentsMap.containsKey(id)) {
      _documentsMap.remove(id);
      _notifyChanges();
      await _saveToDisk();
      return true;
    }
    return false;
  }

  /// Bật/Tắt trạng thái ghim yêu thích
  Future<void> togglePinDocument(String id) async {
    final doc = _documentsMap[id];
    if (doc != null) {
      _documentsMap[id] = doc.copyWith(isPinned: !doc.isPinned);
      _notifyChanges();
      await _saveToDisk();
    }
  }

  /// Cập nhật nhanh trạng thái học tập
  Future<void> updateDocumentStatus(String id, StudyStatus newStatus) async {
    final doc = _documentsMap[id];
    if (doc != null) {
      _documentsMap[id] = doc.copyWith(
        status: newStatus,
        completedDate: newStatus == StudyStatus.completed ? DateTime.now() : null,
      );
      _notifyChanges();
      await _saveToDisk();
    }
  }

  /// Thêm hoặc Cập nhật Môn học
  Future<void> createOrUpdateCourse(CourseModel course) async {
    _coursesMap[course.courseId] = course;
    _notifyChanges();
    await _saveToDisk();
  }

  /// Xóa môn học và các tài liệu liên quan (Cascade Delete)
  Future<void> deleteCourse(String courseId) async {
    _coursesMap.remove(courseId);
    _documentsMap.removeWhere((key, doc) => doc.courseId == courseId);
    _notifyChanges();
    await _saveToDisk();
  }

  /// Khôi phục dữ liệu về mặc định
  Future<void> resetToDefault() async {
    _coursesMap.clear();
    _documentsMap.clear();
    _isInitialized = false;
    _initData();
    await _saveToDisk();
  }

  /// Giải phóng tài nguyên
  void dispose() {
    _documentsStreamController.close();
    _coursesStreamController.close();
  }
}
