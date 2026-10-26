import 'package:flutter/material.dart';
import '../app_services.dart';
import '../../features/home/home_view.dart';
import '../../features/settings/settings_view.dart';
import '../../features/settings/theme_view_model.dart';
import '../../features/auth/auth_view.dart';
import '../../features/auth/auth_view_model.dart';
import '../../features/catalog/catalog_home.dart';
import '../../features/catalog/menu_view.dart';
import '../../features/catalog/favorites_view.dart';
import '../../features/catalog/qr_views.dart';
import '../../features/owner/owner_views.dart';
import '../../shared/widgets/catalog_widgets.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';
  static Route<dynamic> generate(RouteSettings route, ThemeViewModel theme, [AppServices? services]) =>
    MaterialPageRoute<dynamic>(settings: route, builder: (context) {
      if (route.name == settings) return SettingsView(viewModel: theme);
      if (services == null) return HomeView(onSettings: () => Navigator.pushNamed(context, settings));
      final args = route.arguments;
      Widget guard(Widget child) => OwnerGuard(services: services, child: child);
      return switch(route.name) {
        '/' => CatalogHome(services: services),
        '/login' => AuthView(services: services, mode: AuthMode.login),
        '/register' => AuthView(services: services, mode: AuthMode.register),
        '/recovery' => AuthView(services: services, mode: AuthMode.recovery),
        '/password' => guard(AuthView(services: services, mode: AuthMode.password)),
        '/scanner' => const ScannerView(),
        '/favorites' => FavoritesView(services: services),
        '/menu' when args is MenuArgs => MenuView(services: services, slug: args.slug),
        '/product' when args is ProductArgs => ProductView(services: services, args: args),
        '/owner' => guard(OwnerListView(services: services)),
        '/categories' when args is AdminArgs => guard(OwnerListView(services: services, restaurant: args.restaurant, table: 'categories')),
        '/products' when args is AdminArgs => guard(OwnerListView(services: services, restaurant: args.restaurant, table: 'products')),
        '/edit' when args is EditorArgs => guard(EditorView(services: services, args: args)),
        '/qr' when args is AdminArgs => guard(RestaurantQrView(restaurant: args.restaurant)),
        _ => Scaffold(appBar: AppBar(title: const Text('Página não encontrada')), body: const EmptyState('Volte ao início e tente novamente.')),
      };
    });
}
