part of 'file_upload_controller.dart';

/// Handler đặc biệt để xử lý file đã tồn tại (không cần upload)
class PreLoadFileUploadController extends FileUploadController {
  PreLoadFileUploadController({
    required PreloadFileUploadHandler handler,
    FileUploaderLogger? logger,
  })  : _handler = handler,
        _logger = logger,
        super._();

  final PreloadFileUploadHandler _handler;
  final FileUploaderLogger? _logger;

  XFile get file => _handler.file;

  @override
  Future<FileUploadResult> upload({ProgressCallback? onProgress}) async {
    _logger?.info('retry file ${_handler.file.path}');
    onProgress?.call(1, 1);
    _setUploaded();
    return FileUploadResult(
      file: _handler.file,
      id: generateUniqueId(),
    );
  }

  @override
  Future<FileUploadResult> retry({ProgressCallback? onProgress}) {
    return upload(onProgress: onProgress);
  }
}
