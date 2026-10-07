import 'package:flutter/material.dart';

/// Shared, resilient network image widget for hotel and room imagery.
///
/// Features:
/// - Fixed aspect ratio or explicit constraints with zero layout jumps.
/// - Calm, shimmer-like tonal loading placeholder.
/// - Neutral error fallback with descriptive semantics and an explicit Retry action.
/// - Automatic retry when a [reconnectSignal] fires (debounced reconnection).
/// - Memory-bounded image caching via `cacheWidth` and `cacheHeight`.
class HotelNetworkImage extends StatefulWidget {
  const HotelNetworkImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.semanticLabel,
    this.memCacheWidth = 800,
    this.memCacheHeight = 600,
    this.reconnectSignal,
    this.heroTag,
  });

  final String imageUrl;
  final double? aspectRatio;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final String? semanticLabel;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Listenable? reconnectSignal;
  final String? heroTag;

  @override
  State<HotelNetworkImage> createState() => _HotelNetworkImageState();
}

class _HotelNetworkImageState extends State<HotelNetworkImage>
    with SingleTickerProviderStateMixin {
  int _retryAttempt = 0;
  bool _hasError = false;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    widget.reconnectSignal?.addListener(_onReconnect);
  }

  @override
  void didUpdateWidget(covariant HotelNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _retryAttempt = 0;
      _hasError = false;
    }
    if (oldWidget.reconnectSignal != widget.reconnectSignal) {
      oldWidget.reconnectSignal?.removeListener(_onReconnect);
      widget.reconnectSignal?.addListener(_onReconnect);
    }
  }

  void _onReconnect() {
    if (_hasError && mounted) {
      // Auto-retry once on connection restore
      setState(() {
        _hasError = false;
        _retryAttempt++;
      });
    }
  }

  void _manualRetry() {
    if (mounted) {
      setState(() {
        _hasError = false;
        _retryAttempt++;
      });
    }
  }

  @override
  void dispose() {
    widget.reconnectSignal?.removeListener(_onReconnect);
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget imageContent;

    if (_hasError) {
      imageContent = _buildErrorPlaceholder(theme, isDark);
    } else {
      imageContent = Image.network(
        widget.imageUrl,
        key: ValueKey('${widget.imageUrl}_attempt_$_retryAttempt'),
        fit: widget.fit,
        cacheWidth: widget.memCacheWidth,
        cacheHeight: widget.memCacheHeight,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildLoadingPlaceholder(theme, isDark);
        },
        errorBuilder: (context, error, stackTrace) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_hasError) {
              setState(() {
                _hasError = true;
              });
            }
          });
          return _buildErrorPlaceholder(theme, isDark);
        },
      );
    }

    if (widget.heroTag != null) {
      imageContent = Hero(
        tag: widget.heroTag!,
        child: imageContent,
      );
    }

    Widget container = ClipRRect(
      borderRadius: widget.borderRadius,
      child: Container(
        width: widget.width,
        height: widget.height,
        color: isDark ? const Color(0xFF1E2621) : const Color(0xFFF1F5F2),
        child: imageContent,
      ),
    );

    if (widget.aspectRatio != null) {
      container = AspectRatio(
        aspectRatio: widget.aspectRatio!,
        child: container,
      );
    }

    return Semantics(
      label: widget.semanticLabel ?? 'Hotel photo',
      image: true,
      child: container,
    );
  }

  Widget _buildLoadingPlaceholder(ThemeData theme, bool isDark) {
    final baseColor =
        isDark ? const Color(0xFF1E2621) : const Color(0xFFE5EDE8);
    final highlightColor =
        isDark ? const Color(0xFF28332D) : const Color(0xFFF4F8F5);

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + (_shimmerController.value * 2), -0.3),
              end: Alignment(1.0 + (_shimmerController.value * 2), 0.3),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.1, 0.5, 0.9],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 28,
              color: isDark ? Colors.white24 : Colors.black12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme, bool isDark) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final surfaceColor =
        isDark ? const Color(0xFF1C221E) : const Color(0xFFF0F4F1);

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(height: 6),
            Text(
              'Photo unavailable',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _manualRetry,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
