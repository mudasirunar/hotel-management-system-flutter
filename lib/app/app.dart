import 'dart:async';

import 'package:flutter/material.dart';

import '../application/customer_controller.dart';
import '../application/theme_controller.dart';
import '../data/local/hive_customer_repository.dart';
import 'customer_workspace.dart';
import 'theme.dart';

class HotelManagementApp extends StatefulWidget {
  const HotelManagementApp({
    super.key,
    this.customerController,
    this.themeController,
  });

  final CustomerController? customerController;
  final ThemeController? themeController;

  @override
  State<HotelManagementApp> createState() => _HotelManagementAppState();
}

class _HotelManagementAppState extends State<HotelManagementApp> {
  late final CustomerController _customerController;
  late final ThemeController _themeController;
  late final bool _ownedCustomerController;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ?? ThemeController();
    unawaited(_themeController.load());

    if (widget.customerController != null) {
      _customerController = widget.customerController!;
      _ownedCustomerController = false;
      if (_customerController.status == CustomerLoadStatus.initial) {
        unawaited(_customerController.load());
      }
    } else {
      _customerController = CustomerController(repository: HiveCustomerRepository());
      _ownedCustomerController = true;
      unawaited(_customerController.load());
    }
  }

  @override
  void dispose() {
    if (_ownedCustomerController) {
      unawaited(_customerController.close().catchError((Object _) {}));
      _customerController.dispose();
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
          child: _buildCustomerBranch(context),
        ),
      ),
    ),
  );

  Widget _buildCustomerBranch(BuildContext context) {
    return ListenableBuilder(
      listenable: _customerController,
      builder: (context, _) {
        if (_themeController.loading ||
            _customerController.status == CustomerLoadStatus.initial ||
            _customerController.status == CustomerLoadStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(
              semanticsLabel: 'Loading customer catalog',
            ),
          );
        }

        if (_customerController.status == CustomerLoadStatus.failed) {
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
                      _customerController.loadError?.message ??
                          'An unexpected error occurred while loading stays.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => unawaited(_customerController.load()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return CustomerWorkspace(
          customerController: _customerController,
          themeController: _themeController,
        );
      },
    );
  }
}
