import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../file_uploader_utils.dart'; // Giả định có UniqueIdUtils

/// Lớp FileUtils cung cấp các tiện ích để xử lý tất cả các loại file
/// bao gồm download, chuyển đổi và quản lý file tạm thời
class FileUtils {
  // Private constructor để ngăn khởi tạo
  FileUtils._();

  // Set để theo dõi các file tạm thời để dọn dẹp sau này
  static final Set<String> _tempFilePaths = {};

  /// Tải xuống một hoặc nhiều file từ URLs hoặc chuyển đổi
  /// từ File/XFile sang định dạng XFile chuẩn
  ///
  /// Chấp nhận danh sách các đối tượng (URL, XFile, File) và trả về List<XFile>
  /// Mỗi XFile sẽ được đánh dấu nếu đó là file được tải về từ remote
  static Future<List<XFile>> processFiles(List<dynamic> sources) async {
    final results = <XFile>[];

    for (final source in sources) {
      try {
        if (source is String && isRemoteUrl(source)) {
          // Xử lý URL dạng string
          final xFile = await downloadFile(source);
          if (xFile != null) {
            results.add(xFile);
          }
        } else if (source is XFile) {
          // Xử lý XFile trực tiếp
          if (isRemoteUrl(source.path)) {
            // Đây là remote file
            final xFile = await downloadFile(source.path);
            if (xFile != null) {
              results.add(xFile);
            }
          } else {
            // Đây là local file, dùng trực tiếp
            results.add(source);
          }
        } else if (source is File) {
          // Chuyển đổi File thành XFile
          results.add(convertFileToXFile(source));
        } else if (source is Uint8List) {
          // Xử lý dữ liệu nhị phân
          final xFile = await createXFileFromData(source);
          if (xFile != null) {
            results.add(xFile);
          }
        }
      } catch (e) {
        debugPrint('Lỗi xử lý file $source: $e');
        // Tiếp tục với các file khác kể cả khi một file thất bại
      }
    }

    return results;
  }

  /// Tải xuống file từ URL
  ///
  /// Trả về XFile với metadata đánh dấu đây là file đã tải sẵn
  static Future<XFile?> downloadFile(String url) async {
    try {
      // Lấy thư mục tạm thời để lưu trữ các file đã tải xuống
      final tempDir = await getTemporaryDirectory();
      final fileName = _getFileNameFromUrl(url);
      final uniqueFileName = '${generateCustomUniqueId(suffix: fileName)}';
      final filePath = '${tempDir.path}/$uniqueFileName';

      // Tải xuống file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Không thể tải file: ${response.statusCode}');
      }

      // Ghi file vào ổ đĩa
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Theo dõi file này để dọn dẹp sau
      _tempFilePaths.add(filePath);

      // Xác định mime type
      final mimeType =
          response.headers['content-type'] ?? lookupMimeType(filePath);

      // Tạo XFile với metadata
      return XFileWithMetadata(
        filePath,
        mimeType: mimeType,
        metadata: {
          'isPreloaded': true,
          'sourceUrl': url,
          'date': DateTime.now().toIso8601String(),
          'isTemp': true
        },
      );
    } catch (e) {
      debugPrint('Lỗi tải xuống file từ $url: $e');
      return null;
    }
  }

  /// Tạo XFile từ dữ liệu nhị phân
  static Future<XFile?> createXFileFromData(Uint8List data,
      {String? fileName, String? mimeType}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final name = fileName ?? generateCustomUniqueId(suffix: '_file');
      final filePath = '${tempDir.path}/$name';

      // Ghi dữ liệu vào file
      final file = File(filePath);
      await file.writeAsBytes(data);

      // Theo dõi để dọn dẹp
      _tempFilePaths.add(filePath);

      return XFileWithMetadata(
        filePath,
        mimeType:
            mimeType ?? lookupMimeType(filePath) ?? 'application/octet-stream',
        metadata: {'isTemp': true, 'date': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      debugPrint('Lỗi tạo file từ dữ liệu: $e');
      return null;
    }
  }

  /// Dọn dẹp các file tạm thời
  static Future<void> cleanupTempFiles() async {
    int successCount = 0;
    int failCount = 0;

    for (final path in _tempFilePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          successCount++;
        }
      } catch (e) {
        failCount++;
        debugPrint('Lỗi xóa file tạm $path: $e');
      }
    }

    debugPrint('Đã dọn dẹp $successCount file, $failCount file thất bại');
    _tempFilePaths.clear();
  }

  /// Chuyển đổi File thành XFile
  static XFile convertFileToXFile(File file) {
    return XFile(file.path, mimeType: lookupMimeType(file.path));
  }

  /// Kiểm tra xem một đường dẫn có phải là URL từ xa hay không
  static bool isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// Kiểm tra xem một XFile có phải là file đã được tải sẵn không
  static bool isPreloadedFile(XFile file) {
    if (file is XFileWithMetadata) {
      return file.metadata?['isPreloaded'] == true;
    }
    // Fallback: kiểm tra dựa trên tên file
    return file.path.contains('_temp') || _tempFilePaths.contains(file.path);
  }

  /// Lấy tên file từ URL
  static String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
    } catch (_) {}
    return 'downloaded_file_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Lấy extension của file
  static String getFileExtension(String path) {
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return '';
  }

  /// Kiểm tra loại file dựa trên extension hoặc MIME type
  static FileType getFileType(String path, {String? mimeType}) {
    final mime = mimeType ?? lookupMimeType(path);
    final ext = getFileExtension(path);

    if (mime != null) {
      if (mime.startsWith('image/')) return FileType.image;
      if (mime.startsWith('video/')) return FileType.video;
      if (mime.startsWith('audio/')) return FileType.audio;
      if (mime.startsWith('text/')) return FileType.text;
      if (mime.contains('pdf')) return FileType.pdf;
    }

    // Kiểm tra theo extension
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return FileType.image;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return FileType.video;
      case 'mp3':
      case 'wav':
      case 'ogg':
      case 'm4a':
        return FileType.audio;
      case 'pdf':
        return FileType.pdf;
      case 'doc':
      case 'docx':
        return FileType.doc;
      case 'xls':
      case 'xlsx':
        return FileType.excel;
      case 'ppt':
      case 'pptx':
        return FileType.presentation;
      default:
        return FileType.other;
    }
  }

  /// Tạo tên file tạm thời đảm bảo tính duy nhất
  static String generateTempFileName(String extension) {
    return '${generateCustomUniqueId()}.${extension.replaceAll('.', '')}';
  }
}

/// Enum định nghĩa các loại file
enum FileType {
  image,
  video,
  audio,
  pdf,
  doc,
  excel,
  presentation,
  text,
  other
}

/// XFile mở rộng với hỗ trợ metadata
class XFileWithMetadata extends XFile {
  XFileWithMetadata(
    super.path, {
    super.mimeType,
    super.name,
    super.length,
    super.lastModified,
    this.metadata,
  });

  /// Metadata tùy chỉnh cho XFile
  final Map<String, dynamic>? metadata;

  /// Kiểm tra nếu file này là đã được tải sẵn
  bool get isPreloaded => metadata?['isPreloaded'] == true;

  /// Lấy URL gốc của file nếu có
  String? get sourceUrl => metadata?['sourceUrl'] as String?;

  /// Kiểm tra nếu file là tạm thời
  bool get isTemp => metadata?['isTemp'] == true;

  /// Lấy thời gian tạo file
  DateTime? get createdAt {
    final dateStr = metadata?['date'] as String?;
    if (dateStr != null) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {}
    }
    return null;
  }
}

/// Extension cho XFile để cung cấp thêm thông tin và chức năng
extension XFileExtension on XFile {
  /// Kiểm tra nếu file là từ xa (remote)
  bool get isRemoteFile => FileUtils.isRemoteUrl(path);

  /// Kiểm tra nếu file là local
  bool get isLocalFile => !isRemoteFile;

  /// Kiểm tra nếu file đã được tải sẵn
  bool get isPreloadedFile => FileUtils.isPreloadedFile(this);

  /// Lấy loại file dựa trên extension hoặc MIME type
  FileType get fileType => FileUtils.getFileType(path, mimeType: mimeType);

  /// Lấy extension của file
  String get extension => FileUtils.getFileExtension(path);

  /// Kiểm tra file có phải là kiểu cụ thể không
  bool isOfType(FileType type) => fileType == type;

  /// Kiểm tra file có phải là ảnh không
  bool get isImage => fileType == FileType.image;

  /// Kiểm tra file có phải là video không
  bool get isVideo => fileType == FileType.video;
}
