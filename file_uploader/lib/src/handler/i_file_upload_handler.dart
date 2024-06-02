import 'dart:io';
import 'package:file_uploader/file_uploader.dart';

/// The base class from which [FileUploadHandler], [ChunkedFileUploadHandler]
/// and [RestorableChunkedFileUploadHandler] were extended.
///
/// Do not extend [IFileUploadHandler],
/// [FileUploadController] will not handle it!.
abstract class IFileUploadHandler {
  /// constructor
  const IFileUploadHandler({
    required this.file,
  });

  /// file to handle
  final File file;
}
