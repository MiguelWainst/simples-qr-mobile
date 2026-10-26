import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/app_services.dart';
import 'data/local/catalog_cache.dart';
import 'data/local/preferences_repository.dart';
import 'data/remote/secure_session.dart';
import 'features/settings/theme_view_model.dart';
import 'features/settings/connection_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final theme = ThemeViewModel(PreferencesRepository(preferences));
  const definedUrl = String.fromEnvironment('SUPABASE_URL');
  const definedKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final url = definedUrl.isNotEmpty
      ? definedUrl
      : preferences.getString('connection.url') ?? '';
  final key = definedKey.isNotEmpty
      ? definedKey
      : preferences.getString('connection.key') ?? '';
  Future<void> connect(String url, String key) async {
    await Supabase.initialize(
      url: url,
      publishableKey: key,
      authOptions: FlutterAuthClientOptions(
        localStorage: kIsWeb ? null : const SecureSession(),
      ),
    );
    await preferences.setString('connection.url', url);
    await preferences.setString('connection.key', key);
    runApp(
      SimplesQrApp(
        theme: theme,
        services: AppServices(
          cache: CatalogCache(preferences),
          client: Supabase.instance.client,
        ),
      ),
    );
  }

  if (url.isNotEmpty && key.isNotEmpty) {
    try {
      await connect(url, key);
      return;
    } catch (_) {
      /* Show an actionable connection form instead of a blank screen. */
    }
  }
  runApp(ConnectionApp(onConnect: connect, initialUrl: url));
}
