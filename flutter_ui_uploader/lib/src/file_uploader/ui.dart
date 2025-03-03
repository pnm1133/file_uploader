import 'package:en_file_uploader/en_file_uploader.dart';
import 'package:flutter/material.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';
import 'package:provider/provider.dart';

import '../../flutter_file_uploader.dart';

const _kAnimationDuration = Duration(milliseconds: 250);
const _kButtonWidth = 100.0;
const _kButtonHeight = 100.0;
const _kBuilderGap = 8.0;
const _kLimitCount = 20;

/// on pressed add files, more on [FileUploader]
// typedef OnPressedAddFilesCallback = Future<List<XFile>> Function();

typedef OnPressedAddFilesCallback = Future<List<XFile>> Function(
    int remainingFiles);

/// on file added, more on [FileUploader]
typedef OnFileAdded<T> = Future<IFileUploadHandler> Function(XFile file);

/// on pressed add files, more on [FileUploader]
typedef LoadInitialFilesCallback = Future<List<XFile>> Function(int maxFiles);

/// builder, more on [FileUploader]
typedef FileUploaderBuilderCallback<T> = Widget Function(
  BuildContext context,
  FileUploaderRef controller,
);

/// on file uploaded, more on [FileUploader]
typedef OnFileUploaded = void Function(FileUploadResult file);

/// on file removed, more on [FileUploader]
typedef OnFileRemoved = void Function(FileUploadResult file);

/// A horizontal file uploader component that allows adding multiple files
/// and displays them in a horizontal row.
class FileUploaderHorizontal<T> extends StatelessWidget {
  /// Upon tapping, the [onPressedAddFiles] function is triggered,
  /// and then [onFileAdded] is called for each file.
  ///
  /// Use the [builder] to create handlers that will upload the files.
  ///
  /// The callbacks [onFileUploaded] and [onFileRemoved] will be executed when
  /// any handler created in the builder uploads or removes a file.
  ///
  /// The [gap] is the space between the elements created with the builder.
  ///
  /// The [placeholder] is the widget to display in the center of the button.
  ///
  /// [border], [borderRadius], [height], [width]
  /// are used to customize the button's style.
  ///
  /// use [loadingBuilder] to customize the loading widget
  ///
  /// use [errorBuilder] to customize the error widget
  ///
  /// set either [onPressedAddFiles] or [onFileAdded] to disable the `onTap`
  ///
  /// use [color] to customize [border] color and tap effects.
  const FileUploaderHorizontal({
    required this.builder,
    super.key,
    this.height = _kButtonHeight,
    this.width = _kButtonWidth,
    this.onFileAdded,
    this.onPressedAddFiles,
    this.placeholder,
    this.border,
    this.borderRadius,
    this.logger,
    this.gap = _kBuilderGap,
    this.onFileRemoved,
    this.onFileUploaded,
    this.limit,
    this.errorBuilder,
    this.loadingBuilder,
    this.hideOnLimit,
    this.color,
    this.scrollController,
    this.scrollPhysics,
    this.showScrollbar = true,
    this.listHeight,
    this.scrollDirection = Axis.horizontal,
    this.buttonPosition = FileUploaderButtonPosition.end,
    this.onLoadIinitFiles,
  });

  /// height of the button and file items
  final double height;

  /// width of the button
  final double width;

  /// callback fired when [FileUploaderHorizontal] is tapped
  final OnPressedAddFilesCallback? onPressedAddFiles;

  final LoadInitialFilesCallback? onLoadIinitFiles;

  /// after [onPressedAddFiles] for every file the [onFileAdded] is called
  final OnFileAdded? onFileAdded;

  /// every time a file is uploaded
  final OnFileUploaded? onFileUploaded;

  /// every time a file is removed
  final OnFileRemoved? onFileRemoved;

  /// child of button when is waiting files
  final Widget? placeholder;

  /// child of button when some files went in error under processing
  final Widget Function(
    BuildContext context,
    dynamic errorOnFiles,
  )? errorBuilder;

  /// child of button under processing
  /// default is [CircularProgressIndicator]
  final Widget Function(
    BuildContext context,
  )? loadingBuilder;

  /// border radius of button
  final BorderRadiusGeometry? borderRadius;

  /// border of button
  final BoxBorder? border;

  /// used to create the file upload handler
  final FileUploaderBuilderCallback builder;

  /// logger
  final FileUploaderLogger? logger;

  /// gap between [builder] widgets
  final double gap;

  /// maximum number of files that can be uploaded
  final int? limit;

  /// hide file uploader button on limit reached
  final bool? hideOnLimit;

  /// button color used on default [border] and tap effects
  final Color? color;

  /// ScrollController for the horizontal list
  final ScrollController? scrollController;

  /// ScrollPhysics for the horizontal list
  final ScrollPhysics? scrollPhysics;

  /// Whether to show scrollbar for the list
  final bool showScrollbar;

  /// Optional height for the list, defaults to [height]
  final double? listHeight;

  /// Scroll direction of the list, default is horizontal
  final Axis scrollDirection;

  /// Position of the add button (start or end)
  final FileUploaderButtonPosition buttonPosition;

  @override
  Widget build(BuildContext context) {
    return _Provider(
      key: const ValueKey('file_uploader_horizontal_provider'),
      onFileRemoved: onFileRemoved,
      onFileUploaded: onFileUploaded,
      onLoadInitFiles: onLoadIinitFiles,
      onFileAdded: onFileAdded,
      logger: logger,
      limit: limit,
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final listWidget = _buildList(context);

    // Determine if we're using horizontal or vertical layout
    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: listHeight ?? height,
        child: listWidget,
      );
    } else {
      return SizedBox(
        width: width,
        child: listWidget,
      );
    }
  }

  Widget _buildList(BuildContext context) {
    final Widget list = FileUploaderSelector(
      selector: (_, model) => model.refs,
      builder: (context, refs, _) {
        // Create a list of widgets with files and add button
        final items = <Widget>[];

        // File items
        final fileWidgets = refs
            .map(
              (ref) => SizedBox(
                width: width,
                height: height,
                child: builder(context, ref),
              ),
            )
            .toList();

        // Add button
        final button = _Button(
          key: const ValueKey('file_uploader_horizontal_button'),
          onFileAdded: onFileAdded,
          onPressedAddFiles: onPressedAddFiles,
          border: border,
          width: width,
          height: height,
          borderRadius: borderRadius,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          placeholder: placeholder,
          hideOnLimit: hideOnLimit,
          color: color,
        );

        // Position the button according to setting
        if (buttonPosition == FileUploaderButtonPosition.start) {
          items.add(button);
          items.addAll(fileWidgets);
        } else {
          items.addAll(fileWidgets);
          items.add(button);
        }

        // Create row view first
        final rowView = SingleChildScrollView(
          controller: scrollController,
          scrollDirection: scrollDirection,
          physics: scrollPhysics,
          child: Row(
            key: const ValueKey('file_uploader_horizontal_list'),
            children: items.map((item) {
              return Padding(
                padding: EdgeInsets.only(right: gap),
                child: _KeepAliveFileItem(child: item),
              );
            }).toList(),
          ),
        );
        return rowView;
      },
    );
    return list;
  }
}

enum FileUploaderButtonPosition { start, end }

class _Button extends StatelessWidget {
  const _Button({
    required this.onFileAdded,
    required this.onPressedAddFiles,
    required this.border,
    required this.width,
    required this.height,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.placeholder,
    required this.borderRadius,
    required this.hideOnLimit,
    required this.color,
    super.key,
  });

  final OnFileAdded? onFileAdded;
  final OnPressedAddFilesCallback? onPressedAddFiles;
  final BoxBorder? border;
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, dynamic errorOnFiles)?
      errorBuilder;
  final Widget? placeholder;
  final bool? hideOnLimit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        this.borderRadius ?? BorderRadius.circular(kFileUploaderRadius);
    final color = this.color ?? Theme.of(context).colorScheme.secondary;

    return FileUploaderConsumer(
      key: const ValueKey('file_uploader_horizontal_button_builder'),
      builder: (context, model, _) {
        final onTap = model.onPressedAddFiles(
          onFileAdded: onFileAdded,
          onPressedAddFiles: onPressedAddFiles,
        );
        final border = this.border ??
            DashedBorder.all(
              dashLength: 10,
              color: model.reachedLimit ? color.withOpacity(0.3) : color,
            );
        final hide = model.reachedLimit && (hideOnLimit ?? false);

        return AnimatedSwitcher(
          duration: _kAnimationDuration,
          child: hide
              ? const SizedBox()
              : InkWell(
                  key:
                      const ValueKey('file_uploader_horizontal_button_inkwell'),
                  onTap: onTap,
                  radius: kFileUploaderRadius,
                  hoverColor: color.withOpacity(0.1),
                  focusColor: color.withOpacity(0.1),
                  splashColor: color.withOpacity(0.1),
                  highlightColor: color.withOpacity(0.2),
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: border,
                      borderRadius: borderRadius,
                    ),
                    child: _content(context, model),
                  ),
                ),
        );
      },
    );
  }

  Widget _content(BuildContext context, FileUploaderModel model) {
    if (model.processingFiles) {
      return _Loading(
        key: const ValueKey('file_uploader_horizontal_loading'),
        loading: loadingBuilder?.call(context),
      );
    }

    if (model.errorOnFiles != null) {
      return _Error(
        key: const ValueKey('file_uploader_horizontal_error'),
        error:
            errorBuilder?.call(context, model.errorOnFiles) ?? const SizedBox(),
      );
    }

    return _Placeholder(
      key: const ValueKey('file_uploader_horizontal_placeholder'),
      placeholder: placeholder ?? _defaultAddPlaceholder(context),
    );
  }

  Widget _defaultAddPlaceholder(BuildContext context) {
    return Icon(
      Icons.add_circle_outline,
      color: color ?? Theme.of(context).colorScheme.secondary,
    );
  }
}

class _Provider extends StatelessWidget {
  const _Provider({
    required this.logger,
    required this.child,
    required this.onFileRemoved,
    required this.onFileUploaded,
    this.onLoadInitFiles,
    this.onFileAdded, // Thêm tham số này
    this.limit,
    super.key,
  });

  final FileUploaderLogger? logger;
  final Widget child;
  final OnFileUploaded? onFileUploaded;
  final OnFileRemoved? onFileRemoved;
  final LoadInitialFilesCallback? onLoadInitFiles;
  final OnFileAdded? onFileAdded;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final model = FileUploaderModel(
      logger: logger,
      onFileRemoved: onFileRemoved,
      onFileUploaded: onFileUploaded,
      limit: limit,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onLoadInitFiles != null && onFileAdded != null) {
        final initFunction = model.loadInitialFiles(
          loadInitialFilesCallback: onLoadInitFiles,
          onFileAdded: onFileAdded,
        );

        // Gọi function được trả về (nếu có)
        if (initFunction != null) {
          initFunction();
        }
      }
    });

    return ChangeNotifierProvider.value(
      value: model,
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    this.placeholder,
    super.key,
  });

  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: placeholder,
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({
    super.key,
    this.error,
  });

  final Widget? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: error,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({
    required this.loading,
    super.key,
  });

  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: loading ?? const CircularProgressIndicator(),
    );
  }
}

class _KeepAliveFileItem<T> extends StatefulWidget {
  const _KeepAliveFileItem({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<_KeepAliveFileItem> createState() => _KeepAliveFileItemState();
}

class _KeepAliveFileItemState extends State<_KeepAliveFileItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
