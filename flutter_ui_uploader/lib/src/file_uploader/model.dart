import 'package:cross_file/cross_file.dart';
import 'package:en_file_uploader/en_file_uploader.dart';
import 'package:flutter/material.dart';
import '../../flutter_file_uploader.dart';
import 'ui.dart';

/// The model that manages file uploads and removals.
class FileUploaderModel with ChangeNotifier {
  /// The model that manages file uploads and removals.
  FileUploaderModel({
    FileUploaderLogger? logger,
    OnFileUploaded? onFileUploaded,
    OnFileRemoved? onFileRemoved,
    this.limit,
  })  : _processingFiles = false,
        _controllers = List<FileUploadController>.unmodifiable([]),
        _logger = logger,
        _filesUploaded = {},
        _errorOnFiles = null,
        _onFileUploaded = onFileUploaded,
        _onFileRemoved = onFileRemoved {}

  bool _processingFiles;

  /// true if there are files under processing (during [onPressedAddFiles])
  bool get processingFiles => _processingFiles;

  dynamic _errorOnFiles;

  /// error during [onPressedAddFiles]
  /// null: no error present
  ///
  /// else: the error caught
  dynamic get errorOnFiles => _errorOnFiles;

  final OnFileUploaded? _onFileUploaded;
  final OnFileRemoved? _onFileRemoved;

  List<FileUploadController> _controllers;

  /// The references to be used by the widgets that handle file uploads:
  Iterable<FileUploaderRef> get refs {
    return _controllers.map(_fileUploaderRefBuilder);
  }

  /// preserve files uploaded
  final Map<FileUploadController, FileUploadResult> _filesUploaded;

  /// logger
  final FileUploaderLogger? _logger;

  /// maximum number of files that can be uploaded
  final int? limit;

  /// files uploaded reach the available limit
  bool get reachedLimit {
    if (limit == null) {
      return false;
    }

    return _controllers.length >= limit!;
  }

  /// Returns the callback to execute when you want to handle a set of files.
  ///
  /// If either [onPressedAddFiles] or [onFileAdded] is provided, no callback
  /// is returned (which is useful to disable button callbacks)
  ///
  /// Executing the callback will:
  ///
  /// 1. call [onPressedAddFiles].
  /// 2. after files are added, call [onFileAdded] for each file;
  Future<void> Function()? onPressedAddFiles({
    OnPressedAddFilesCallback? onPressedAddFiles,
    OnFileAdded? onFileAdded,
  }) {
    if (_processingFiles || reachedLimit) {
      return null;
    }

    if (onPressedAddFiles == null || onFileAdded == null) {
      return null;
    }

    return () async {
      try {
        _setProcessing();

        // Tính toán số lượng file còn lại có thể thêm
        final remainingCount =
            limit != null ? limit! - _controllers.length : 20;

        final files = await onPressedAddFiles(remainingCount);
        final controllers = <FileUploadController>[];

        await Future.forEach(files, (file) async {
          controllers.add(
            _controllerBuilder(
              await onFileAdded(file),
              preUploaded: false,
            ),
          );
        });

        _setStopProcessing(controllers);
      } catch (e, stackTrace) {
        _setErrorOnProcessing(e, stackTrace);
      }
    };
  }

  Future<void> Function()? loadInitialFiles({
    required LoadInitialFilesCallback? loadInitialFilesCallback,
    OnFileAdded? onFileAdded,
  }) {
    if (processingFiles || reachedLimit) {
      return null;
    }
    if (loadInitialFilesCallback == null || onFileAdded == null) {
      return null;
    }
    return () async {
      try {
        // Tính toán số lượng file tối đa có thể tải
        final int maxCount = limit ?? 20;

        _setProcessing();
        final files = await loadInitialFilesCallback(maxCount);
        final controllers = <FileUploadController>[];
        await Future.forEach(files, (file) async {
          // Tạo handler cho file
          final handler = await onFileAdded(file);
          // Kiểm tra xem file đã được upload chưa
          // Đối với files từ remote URLs, đánh dấu là đã upload
          final isPreUploaded = _isRemoteFile(file);

          // Tạo controller với trạng thái đã upload hoặc chưa
          controllers.add(
            _controllerBuilder(
              handler,
              preUploaded: isPreUploaded,
            ),
          );
        });
        _setStopProcessing(controllers);
      } catch (e, stackTrace) {
        _setErrorOnProcessing(e, stackTrace);
      }
    };
  }

  // Hàm tiện ích để kiểm tra file từ remote
  bool _isRemoteFile(XFile file) {
    // Kiểm tra file path để xác định nguồn gốc
    return file.path.endsWith('-temp');
  }

  /// remove [FileUploadController] from [_controllers] and
  ///
  /// remove [FileUploadResult] from [_filesUploaded]
  ///
  /// call [_onFileRemoved]
  void _onRemoved(FileUploadController controller) {
    final file = _filesUploaded[controller];
    if (file == null) {
      return;
    }

    _controllers = List.unmodifiable([..._controllers]..remove(controller));
    _filesUploaded.remove(controller);
    _onFileRemoved?.call(file);
    notifyListeners();
  }

  /// add [FileUploadResult] to [_filesUploaded]
  ///
  /// call [_onFileUploaded]
  void _onUploaded(
    FileUploadController controller,
    FileUploadResult result,
  ) {
    _filesUploaded.putIfAbsent(controller, () => result);
    _onFileUploaded?.call(result);
    notifyListeners();
  }

  /// [FileUploadController] builder với tham số preUploaded
  FileUploadController _controllerBuilder(
    IFileUploadHandler handler, {
    bool preUploaded = false,
  }) {
    return FileUploadController(
      handler,
      logger: _logger,
      preUploaded: preUploaded,
    );
  }

  /// [FileUploaderRef] builder
  FileUploaderRef _fileUploaderRefBuilder(
    FileUploadController controller,
  ) {
    return FileUploaderRef(
      controller: controller,
      onRemoved: () => _onRemoved(controller),
      onUpload: (result) => _onUploaded(controller, result),
    );
  }

  /// start processing
  void _setProcessing() {
    _errorOnFiles = null;
    _processingFiles = true;
    notifyListeners();
  }

  /// stop processing (controllers are available)
  void _setStopProcessing(List<FileUploadController> controllers) {
    _processingFiles = false;
    _errorOnFiles = null;
    _controllers = List.unmodifiable([..._controllers, ...controllers]);
    notifyListeners();
  }

  /// set error
  void _setErrorOnProcessing(e, stackTrace) {
    _processingFiles = false;
    _errorOnFiles = e;
    _logger?.error(e.toString(), e, stackTrace);
    notifyListeners();
  }
}
