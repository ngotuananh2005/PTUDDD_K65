/// Định nghĩa Schema CSDL theo phong cách Drift/SQLite của Cashew
class StudyDatabaseSchema {
  // Tên các bảng
  static const String tableCourses = 'courses';
  static const String tableDocuments = 'documents';
  static const String tableTags = 'tags';

  // Câu lệnh DDL khởi tạo bảng Courses (Môn học)
  static const String createTableCourses = '''
    CREATE TABLE IF NOT EXISTS $tableCourses (
      courseId TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      code TEXT NOT NULL UNIQUE,
      description TEXT,
      colorValue INTEGER NOT NULL,
      iconCodePoint INTEGER NOT NULL,
      orderIndex INTEGER DEFAULT 0,
      dateCreated TEXT NOT NULL
    );
  ''';

  // Câu lệnh DDL khởi tạo bảng Documents (Tài liệu học tập)
  static const String createTableDocuments = '''
    CREATE TABLE IF NOT EXISTS $tableDocuments (
      id TEXT PRIMARY KEY NOT NULL,
      title TEXT NOT NULL,
      description TEXT,
      courseId TEXT NOT NULL,
      type TEXT NOT NULL,
      status TEXT NOT NULL,
      priority TEXT NOT NULL,
      fileUrl TEXT,
      pageCount INTEGER DEFAULT 0,
      estimatedMinutes INTEGER DEFAULT 30,
      isPinned INTEGER DEFAULT 0,
      dateCreated TEXT NOT NULL,
      dueDate TEXT,
      completedDate TEXT,
      tags TEXT,
      FOREIGN KEY (courseId) REFERENCES $tableCourses (courseId) ON DELETE CASCADE
    );
  ''';
}
