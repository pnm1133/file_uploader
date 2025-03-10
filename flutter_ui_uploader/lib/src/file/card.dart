import 'package:flutter/material.dart';

const _kAnimationDuration = Duration(milliseconds: 250);
const kFileUploaderRadius = 8.0;

/// An agnostic file upload widget.
///
/// Use [ProvidedFileCard] to build [FileCard] with business logic
class FileCard extends StatelessWidget {
  /// Constructor to build an agnostic file upload widget.
  const FileCard({
    required this.content,
    required this.status,
    this.progress = 0.0,
    this.retryIcon = Icons.rotate_left_rounded,
    this.removeIcon = Icons.delete,
    this.borderRadius,
    this.elevation,
    this.onRemove,
    this.onRetry,
    this.padding = const EdgeInsets.all(8),
    this.progressHeight = 10,
    this.removeColor,
    this.retryColor,
    this.uploadIcon = Icons.upload,
    this.onUpload,
    this.uploadColor,
    super.key,
  });

  /// border radius applied on card
  final BorderRadius? borderRadius;

  /// [FileCard.content] padding
  final EdgeInsetsGeometry padding;

  /// card elevation
  final double? elevation;

  /// upload progress (0..1)
  final double progress;

  /// height of the progress indicator
  final double progressHeight;

  /// card child
  ///
  /// Starting from the left, it expands up to the call to action.
  ///
  /// Below the content, there is a LinearProgressIndicator.
  final Widget content;

  /// upload button icon
  final IconData uploadIcon;

  /// upload button callback
  final VoidCallback? onUpload;

  /// upload button color
  final Color? uploadColor;

  /// retry button icon
  final IconData retryIcon;

  /// retry button callback
  final VoidCallback? onRetry;

  /// retry button color
  final Color? retryColor;

  /// remove button icon
  final IconData removeIcon;

  /// remove button callback
  final VoidCallback? onRemove;

  /// remove button color
  final Color? removeColor;

  /// upload status
  final FileUploadStatus status;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(kFileUploaderRadius);

    return AnimatedOpacity(
      duration: _kAnimationDuration,
      opacity: status.disabled ? 0.8 : 1,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: radius),
        elevation: elevation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: padding,
              child: _FileCardContent(
                content: content,
                removeIcon: removeIcon,
                retryIcon: retryIcon,
                semantic: status,
                onRemove: onRemove,
                onRetry: onRetry,
                uploadColor: uploadColor,
                uploadIcon: uploadIcon,
                onUpload: onUpload,
                removeColor: removeColor,
                retryColor: retryColor,
              ),
            ),
            _FileCardProgress(
              radius: radius,
              progress: progress,
              height: progressHeight,
            ),
          ],
        ),
      ),
    );
  }
}

class _FileCardContent extends StatelessWidget {
  const _FileCardContent({
    required this.content,
    required this.uploadIcon,
    required this.uploadColor,
    required this.retryIcon,
    required this.removeIcon,
    required this.semantic,
    this.onUpload,
    this.onRetry,
    this.retryColor,
    this.onRemove,
    this.removeColor,
  }) : super(key: const ValueKey('_file_card_content'));

  final Widget content;

  final IconData uploadIcon;
  final VoidCallback? onUpload;
  final Color? uploadColor;

  final IconData retryIcon;
  final VoidCallback? onRetry;
  final Color? retryColor;

  final IconData removeIcon;
  final VoidCallback? onRemove;
  final Color? removeColor;

  final FileUploadStatus semantic;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        content,
        AnimatedSwitcher(
          duration: _kAnimationDuration,
          child: _action(context),
        ),
      ],
    );
  }

  Widget _action(BuildContext context) {
    final theme = Theme.of(context);

    if (semantic.showRemove) {
      return _FileCardButton(
        key: const ValueKey('remove_button'),
        iconData: removeIcon,
        onPressed: onRemove,
        color: removeColor ?? theme.colorScheme.error,
      );
    }
    if (semantic.showRetry) {
      return _FileCardButton(
        key: const ValueKey('retry_button'),
        iconData: retryIcon,
        onPressed: onRetry,
        color: retryColor ?? theme.colorScheme.error,
      );
    }
    if (semantic.showUpload) {
      return _FileCardButton(
        key: const ValueKey('upload_button'),
        iconData: uploadIcon,
        onPressed: onUpload,
        color: uploadColor ?? theme.colorScheme.primary,
      );
    }

    // fake button for layout
    return _FileCardButton(
      key: const ValueKey('fake_button'),
      iconData: uploadIcon,
      color: Colors.transparent,
    );
  }
}

class _FileCardProgress extends StatefulWidget {
  const _FileCardProgress({
    required this.progress,
    required this.radius,
    required this.height,
  }) : super(key: const ValueKey('_file_card_progress'));

  final double progress;
  final BorderRadius radius;
  final double height;

  @override
  State<_FileCardProgress> createState() => _FileCardProgressState();
}

class _FileCardProgressState extends State<_FileCardProgress> {
  late double _lastProgress;

  @override
  void initState() {
    _lastProgress = 0;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _FileCardProgress oldWidget) {
    _lastProgress = oldWidget.progress;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder(
      duration: _kAnimationDuration,
      tween: Tween(begin: _lastProgress, end: widget.progress),
      builder: (context, tweenProgress, child) {
        return LinearProgressIndicator(
          value: tweenProgress,
          minHeight: widget.height,
          backgroundColor: theme.colorScheme.secondary,
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.only(
            bottomLeft: widget.radius.bottomLeft,
            bottomRight: widget.radius.bottomRight,
          ),
        );
      },
    );
  }
}

class _FileCardButton extends StatelessWidget {
  const _FileCardButton({
    required this.iconData,
    required this.color,
    super.key,
    this.onPressed,
  });

  final IconData iconData;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.outlinedButtonTheme.style ?? const ButtonStyle();

    final stateColor = WidgetStatePropertyAll(color);

    return OutlinedButton(
      style: style.copyWith(
        iconColor: stateColor,
        shadowColor: stateColor,
        overlayColor: WidgetStatePropertyAll(
          color.withOpacity(0.1),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(
            color: color,
          ),
        ),
      ),
      onPressed: onPressed,
      child: Icon(iconData),
    );
  }
}

enum FileUploadStatus {
  uploading,
  waiting,
  failed,
  done;

  bool get showRemove => this == FileUploadStatus.done;
  bool get showRetry => this == FileUploadStatus.failed;
  bool get showUpload => this == FileUploadStatus.waiting;
  bool get disabled => this == FileUploadStatus.uploading;
}
