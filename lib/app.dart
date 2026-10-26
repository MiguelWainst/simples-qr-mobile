import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_services.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/theme_view_model.dart';

class SimplesQrApp extends StatefulWidget {
  const SimplesQrApp({required this.theme, this.services, super.key});
  final ThemeViewModel theme;
  final AppServices? services;
  @override
  State<SimplesQrApp> createState() => _SimplesQrAppState();
}
class _SimplesQrAppState extends State<SimplesQrApp> {
  final _navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _subscription;
  @override
  void initState() {
    super.initState();
    _subscription = widget.services?.client?.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { _navigator.currentState?.pushNamed('/password'); }
        });
      }
    });
  }
  @override
  void dispose() { _subscription?.cancel(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.theme,
    builder: (_, _) => MaterialApp(
      navigatorKey: _navigator,
      title: 'Simples QR', debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light),
      darkTheme: AppTheme.build(Brightness.dark), themeMode: widget.theme.mode,
      initialRoute: '/',
      onGenerateInitialRoutes: (initial) {
        final code = Uri.base.queryParameters['menu'];
        return [
          AppRoutes.generate(const RouteSettings(name: '/'), widget.theme, widget.services),
          if (code != null && code.isNotEmpty)
            AppRoutes.generate(RouteSettings(name: '/menu', arguments: MenuArgs(code)), widget.theme, widget.services),
        ];
      },
      onGenerateRoute: (settings) => AppRoutes.generate(settings, widget.theme, widget.services),
    ),
  );
}
