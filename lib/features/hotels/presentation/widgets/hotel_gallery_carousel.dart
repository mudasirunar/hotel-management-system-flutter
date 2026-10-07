import 'package:flutter/material.dart';

import '../../../../shared/widgets/hotel_network_image.dart';

/// Photo gallery slider with page indicators and full-screen view support.
class HotelGalleryCarousel extends StatefulWidget {
  const HotelGalleryCarousel({
    super.key,
    required this.hotelId,
    required this.images,
    this.aspectRatio = 16 / 10,
    this.reconnectSignal,
  });

  final String hotelId;
  final List<String> images;
  final double aspectRatio;
  final Listenable? reconnectSignal;

  @override
  State<HotelGalleryCarousel> createState() => _HotelGalleryCarouselState();
}

class _HotelGalleryCarouselState extends State<HotelGalleryCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openFullScreenViewer(int initialIndex) {
    if (widget.images.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _FullScreenImageViewer(
          hotelId: widget.hotelId,
          images: widget.images,
          initialIndex: initialIndex,
          reconnectSignal: widget.reconnectSignal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: const Color(0xFF1C221E),
          child: const Center(
            child: Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.white38),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. PageView of images
          PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final url = images[index];
              return GestureDetector(
                onTap: () => _openFullScreenViewer(index),
                child: HotelNetworkImage(
                  imageUrl: url,
                  aspectRatio: widget.aspectRatio,
                  fit: BoxFit.cover,
                  semanticLabel: 'Hotel photo ${index + 1} of ${images.length}',
                  reconnectSignal: widget.reconnectSignal,
                  heroTag: index == 0 ? 'hotel_hero_${widget.hotelId}' : null,
                ),
              );
            },
          ),

          // 2. Bottom shadow vignette
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Page count pill badge
          if (images.length > 1)
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

          // 4. Dot indicators
          if (images.length > 1)
            Positioned(
              left: 16,
              bottom: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(images.length, (index) {
                  final isSelected = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 5),
                    width: isSelected ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full screen interactive photo viewer.
class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.hotelId,
    required this.images,
    required this.initialIndex,
    this.reconnectSignal,
  });

  final String hotelId;
  final List<String> images;
  final int initialIndex;
  final Listenable? reconnectSignal;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _controller;
  late int _active;

  @override
  void initState() {
    super.initState();
    _active = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.75),
        foregroundColor: Colors.white,
        title: Text(
          'Photo ${_active + 1} of ${widget.images.length}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (i) => setState(() => _active = i),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              child: HotelNetworkImage(
                imageUrl: widget.images[index],
                aspectRatio: 16 / 10,
                fit: BoxFit.contain,
                reconnectSignal: widget.reconnectSignal,
              ),
            ),
          );
        },
      ),
    );
  }
}
