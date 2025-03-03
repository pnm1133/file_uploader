import 'package:flutter/material.dart';
import 'card.dart';

const _kAnimationDuration = Duration(milliseconds: 250);
const kHorizontalFileUploaderRadius = 8.0;

/// An agnostic horizontal file upload widget.
///
/// Designed to be used within FileUploaderHorizontal for consistent design.
class HorizontalFileCard extends StatelessWidget {
  /// Constructor to build an agnostic horizontal file upload widget.
  const HorizontalFileCard({
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
    this.progressHeight = 4,
    this.removeColor,
    this.retryColor,
    this.uploadIcon = Icons.upload,
    this.onUpload,
    this.uploadColor,
    this.width = 100, // Chiều rộng mặc định
    this.height = 100, // Chiều cao mặc định
    this.actionPosition = HorizontalCardActionPosition.top,
    this.progressPosition = HorizontalCardProgressPosition.bottom,
    this.enableUpload = true,
    super.key,
  });

  /// isEnable upload button
  final bool enableUpload;

  /// border radius applied on card
  final BorderRadius? borderRadius;

  /// [HorizontalFileCard.content] padding
  final EdgeInsetsGeometry padding;

  /// card elevation
  final double? elevation;

  /// upload progress (0..1)
  final double progress;

  /// height of the progress indicator
  final double progressHeight;

  /// card child
  final Widget content;

  /// card width
  final double width;

  /// card height
  final double height;

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

  /// Position of the action button
  final HorizontalCardActionPosition actionPosition;

  /// Position of the progress indicator
  final HorizontalCardProgressPosition progressPosition;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(kHorizontalFileUploaderRadius);

    return AnimatedOpacity(
      duration: _kAnimationDuration,
      opacity: status.disabled ? 0.8 : 1,
      child: SizedBox(
        width: width,
        height: height,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: elevation,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: padding,
                  child: Center(child: content),
                ),
              ),
              _buildActionButton(context, radius),
              _buildProgressIndicator(context, radius),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, BorderRadius radius) {
    final action = _getActionWidget(context);

    // Nếu không có action nào, return SizedBox.shrink()
    if (action == null) {
      return const SizedBox.shrink();
    }

    // Vị trí của action button
    switch (actionPosition) {
      case HorizontalCardActionPosition.top:
        return Positioned(
          top: 4,
          right: 4,
          child: action,
        );
      case HorizontalCardActionPosition.bottom:
        return Positioned(
          bottom: 4,
          right: 4,
          child: action,
        );
      case HorizontalCardActionPosition.center:
        return Positioned.fill(
          child: Center(child: action),
        );
      case HorizontalCardActionPosition.overlay:
        return Positioned.fill(
          child: Container(
            color: Colors.black26,
            child: Center(child: action),
          ),
        );
    }
  }

  Widget _buildProgressIndicator(BuildContext context, BorderRadius radius) {
    // Nếu đang chờ hoặc đã hoàn thành, không hiển thị thanh tiến trình
    if (status == FileUploadStatus.waiting || status == FileUploadStatus.done) {
      return const SizedBox.shrink();
    }

    // Vị trí của thanh tiến trình
    switch (progressPosition) {
      case HorizontalCardProgressPosition.bottom:
        return Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _HorizontalProgressIndicator(
            progress: progress,
            height: progressHeight,
            radius: radius,
            position: progressPosition,
          ),
        );
      case HorizontalCardProgressPosition.top:
        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _HorizontalProgressIndicator(
            progress: progress,
            height: progressHeight,
            radius: radius,
            position: progressPosition,
          ),
        );
    }
  }

  Widget? _getActionWidget(BuildContext context) {
    final theme = Theme.of(context);
    if (status == FileUploadStatus.uploading) {
      return _ActionButton(
        key: const ValueKey('cancel_button'),
        iconData: Icons.cancel,
        onPressed: onRemove,
        color: removeColor ?? theme.colorScheme.error,
        mini: actionPosition != HorizontalCardActionPosition.overlay,
      );
    }

    if (status.showRemove) {
      return _ActionButton(
        key: const ValueKey('remove_button'),
        iconData: removeIcon,
        onPressed: onRemove,
        color: removeColor ?? theme.colorScheme.error,
        mini: actionPosition != HorizontalCardActionPosition.overlay,
      );
    }

    if (status.showRetry) {
      return _ActionButton(
        key: const ValueKey('retry_button'),
        iconData: retryIcon,
        onPressed: onRetry,
        color: retryColor ?? theme.colorScheme.error,
        mini: actionPosition != HorizontalCardActionPosition.overlay,
      );
    }

    if (status.showUpload) {
      return _ActionButton(
        key: const ValueKey('upload_button'),
        iconData: uploadIcon,
        onPressed: onUpload,
        color: uploadColor ?? theme.colorScheme.primary,
        mini: actionPosition != HorizontalCardActionPosition.overlay,
      );
    }

    return null;
  }
}

enum HorizontalCardActionPosition {
  top,
  bottom,
  center,
  overlay,
}

enum HorizontalCardProgressPosition {
  bottom,
  top,
}

/// Nút hành động nhỏ hơn cho HorizontalFileCard
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.iconData,
    required this.color,
    super.key,
    this.onPressed,
    this.mini = true,
  });

  final IconData iconData;
  final VoidCallback? onPressed;
  final Color color;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    if (mini) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 16,
              color: color,
            ),
          ),
        ),
      );
    } else {
      // Nút lớn hơn cho overlay mode
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: color,
        mini: false,
        child: Icon(iconData),
      );
    }
  }
}

/// Thanh tiến trình cho HorizontalFileCard
class _HorizontalProgressIndicator extends StatefulWidget {
  const _HorizontalProgressIndicator({
    required this.progress,
    required this.height,
    required this.radius,
    required this.position,
  });

  final double progress;
  final double height;
  final BorderRadius radius;
  final HorizontalCardProgressPosition position;

  @override
  State<_HorizontalProgressIndicator> createState() =>
      _HorizontalProgressIndicatorState();
}

class _HorizontalProgressIndicatorState
    extends State<_HorizontalProgressIndicator> {
  late double _lastProgress;

  @override
  void initState() {
    _lastProgress = 0;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _HorizontalProgressIndicator oldWidget) {
    _lastProgress = oldWidget.progress;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Xác định BorderRadius phù hợp với vị trí
    final borderRadius =
        widget.position == HorizontalCardProgressPosition.bottom
            ? BorderRadius.only(
                bottomLeft: widget.radius.bottomLeft,
                bottomRight: widget.radius.bottomRight,
              )
            : BorderRadius.only(
                topLeft: widget.radius.topLeft,
                topRight: widget.radius.topRight,
              );

    return TweenAnimationBuilder(
      duration: _kAnimationDuration,
      tween: Tween(begin: _lastProgress, end: widget.progress),
      builder: (context, tweenProgress, child) {
        return LinearProgressIndicator(
          value: tweenProgress,
          minHeight: widget.height,
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
          color: theme.colorScheme.primary,
          borderRadius: borderRadius,
        );
      },
    );
  }
}
