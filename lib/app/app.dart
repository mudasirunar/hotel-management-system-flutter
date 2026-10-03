import 'dart:async';

import 'package:flutter/material.dart';

import '../application/hotel_controller.dart';
import '../data/local/hive_hotel_repository.dart';

class HotelManagementApp extends StatefulWidget {
  const HotelManagementApp({super.key, this.controller});

  final HotelController? controller;

  @override
  State<HotelManagementApp> createState() => _HotelManagementAppState();
}

class _HotelManagementAppState extends State<HotelManagementApp> {
  late final HotelController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? HotelController(repository: HiveHotelRepository());
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      unawaited(_controller.close().catchError((Object _) {}));
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Hotel Management System',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF21665E)),
    ),
    home: Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => switch (_controller.status) {
            HotelLoadStatus.initial || HotelLoadStatus.loading => const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading hotel records',
              ),
            ),
            HotelLoadStatus.failed => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Unable to open your records',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _controller.loadError!.message,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => unawaited(_controller.load()),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            HotelLoadStatus.ready => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Hotel Management System',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          },
        ),
      ),
    ),
  );
}
