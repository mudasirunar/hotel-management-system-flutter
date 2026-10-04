import 'dart:async';
import 'package:flutter/material.dart';
import '../application/hotel_controller.dart';
import '../application/theme_controller.dart';
import '../data/local/hive_hotel_repository.dart';
import '../features/rooms/presentation/rooms_screen.dart';
import 'theme.dart';

class HotelManagementApp extends StatefulWidget {
  const HotelManagementApp({super.key, this.controller, this.themeController});

  final HotelController? controller;
  final ThemeController? themeController;

  @override
  State<HotelManagementApp> createState() => _HotelManagementAppState();
}

class _HotelManagementAppState extends State<HotelManagementApp> {
  late final HotelController _controller;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? HotelController(repository: HiveHotelRepository());
    _themeController = widget.themeController ?? ThemeController();
    unawaited(_themeController.load());
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      unawaited(_controller.close().catchError((Object _) {}));
      _controller.dispose();
    }
    if (widget.themeController == null) {
      unawaited(_themeController.close().catchError((Object _) {}));
      _themeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _themeController,
    builder: (context, _) => MaterialApp(
      title: 'Hotel Management System',
      debugShowCheckedModeBanner: false,
      theme: HotelTheme.light,
      darkTheme: HotelTheme.dark,
      themeMode: _themeController.mode,
      home: Scaffold(
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _themeController.loading
                ? const Center(
                    child: CircularProgressIndicator(
                      semanticsLabel: 'Loading appearance',
                    ),
                  )
                : switch (_controller.status) {
                    HotelLoadStatus.initial ||
                    HotelLoadStatus.loading => const Center(
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
                    HotelLoadStatus.ready => RoomsScreen(
                      controller: _controller,
                      themeController: _themeController,
                    ),
                  },
          ),
        ),
      ),
    ),
  );
}
