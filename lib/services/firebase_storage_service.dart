import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Kết quả tải file lên Firebase Storage
class StorageUploadResult {
  final String downloadUrl;
  final String storagePath;
  final String fileName;
  final int fileSize;

  const StorageUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.fileName,
    required this.fileSize,
  });
}

/// Service quản lý lưu trữ tệp tin trên Firebase Storage
/// Cấu trúc thư mục: documents/{userId}/{documentId}/{fileName}
class FirebaseStorageService {
  FirebaseStorage? get _storage {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseStorage.instance;
    } catch (e) {
      debugPrint('Firebase Storage chưa sẵn sàng: $e');
      return null;
    }
  }

  /// Tải tệp tin (dưới dạng mảng bytes Uint8List) lên Firebase Storage
  /// Tương thích 100% trên mọi nền tảng (Web, Android, iOS, Windows)
  Future<StorageUploadResult> uploadDocumentFile({
    required String userId,
    required String documentId,
    required String fileName,
    required Uint8List fileBytes,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final storage = _storage;
    if (storage == null) {
      throw Exception('Firebase Storage chưa được khởi tạo.');
    }

    // Chuẩn hóa đường dẫn lưu trữ theo kiến trúc: documents/{userId}/{documentId}/{fileName}
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
    final storagePath = 'documents/$userId/$documentId/$sanitizedFileName';
    final ref = storage.ref().child(storagePath);

    final metadata = SettableMetadata(
      contentType: mimeType ?? _guessContentType(fileName),
      customMetadata: {
        'userId': userId,
        'documentId': documentId,
        'originalName': fileName,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putData(fileBytes, metadata);

    // Lắng nghe tiến trình upload nếu có callback
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        }
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return StorageUploadResult(
      downloadUrl: downloadUrl,
      storagePath: storagePath,
      fileName: fileName,
      fileSize: fileBytes.length,
    );
  }

  /// Xóa tệp tin trên Firebase Storage theo đường dẫn storagePath
  Future<void> deleteDocumentFile(String storagePath) async {
    final storage = _storage;
    if (storage == null || storagePath.trim().isEmpty) return;

    try {
      final ref = storage.ref().child(storagePath);
      await ref.delete();
    } catch (e) {
      debugPrint('Lỗi khi xóa file Storage ($storagePath): $e');
    }
  }

  /// Tự động phỏng đoán Content-Type dựa theo phần mở rộng file
  String _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}
