import 'dart:async';

import 'package:flutter/material.dart';

import '../application/customer_controller.dart';
import '../application/hotel_controller.dart';
import '../application/theme_controller.dart';
import '../data/local/hive_customer_repository.dart';
import '../data/local/hive_hotel_repository.dart';
import 'customer_workspace.dart';
import 'navigation.dart';
import 'theme.dart';

class HotelManagementApp extends StatefulWidget {
  const HotelManagementApp({
    super.key,
    this.controller,
    this.customerController,
    this.themeController,
  });

  final HotelController? controller;
  final CustomerController? customerController;
  final ThemeController? themeController;

  @override
  State<HotelManagementApp> createState() => _HotelManagementAppState();
}

class _HotelManagementAppState extends State<HotelManagementApp> {
  HotelController? _staffController;
  CustomerController? _customerController;
  late final ThemeController _themeController;

  bool get _isStaffMode => widget.controller != null;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ?? ThemeController();
    unawaited(_themeController.load());

    if (_isStaffMode) {
      _staffController = widget.controller ?? HotelController(repository: HiveHotelRepository());
      unawaited(_staffController!.load());
    } else {
      _customerController = widget.customerController ??
          CustomerController(repository: HiveCustomerRepository());
      unawaited(_customerController!.load());
    }
  }

  @override
  void dispose() {
    if (_staffController != null && widget.controller == null) {
      unawaited(_staffController!.close().catchError((Object _) {}));
      _staffController!.dispose();
    }
    if (_customerController != null && widget.customerController == null) {
      _customerController!.dispose();
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
          bottom: false,
          child: _isStaffMode ? _buildStaffBranch(context) : _buildCustomerBranch(context),
        ),
      ),
    ),
  );

  Widget _buildCustomerBranch(BuildContext context) {
    final controller = _customerController!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (_themeController.loading ||
            controller.status == CustomerLoadStatus.initial ||
            controller.status == CustomerLoadStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading customer catalog',
            ),
          );
        }

        if (controller.status == CustomerLoadStatus.failed) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to open hotel catalog',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      controller.loadError?.message ??
                          'An unexpected error occurred while loading stays.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => unawaited(controller.load()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return CustomerWorkspace(
          customerController: controller,
          themeController: _themeController,
        );
      },
    );
  }

  Widget _buildStaffBranch(BuildContext context) {
    final controller = _staffController!;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _themeController.loading
          ? const Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Loading appearance',
              ),
            )
          : switch (controller.status) {
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
                            controller.loadError!.message,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () => unawaited(controller.load()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              HotelLoadStatus.ready => HotelWorkspace(
                controller: controller,
                themeController: _themeController,
              ),
            },
    );
  }
}
