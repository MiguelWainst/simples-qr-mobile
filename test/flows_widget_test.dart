import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:simples_qr/core/app_services.dart';
import 'package:simples_qr/data/local/catalog_cache.dart';
import 'package:simples_qr/domain/catalog.dart';
import 'package:simples_qr/features/auth/auth_view.dart';
import 'package:simples_qr/features/auth/auth_view_model.dart';
import 'package:simples_qr/features/catalog/favorites_view.dart';

void main() {
  late AppServices services;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    services = AppServices(
      cache: CatalogCache(
        await SharedPreferences.getInstance(),
        useSqlite: false,
      ),
      client: SupabaseClient('https://example.supabase.co', 'public-key'),
    );
  });
  tearDown(() async {
    await services.client!.dispose();
  });
  testWidgets('Cadastro impede envio de email e senha inválidos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthView(services: services, mode: AuthMode.register),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'invalido');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar conta'));
    await tester.pump();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Detalhes salvam favorito e confirmam remoção', (tester) async {
    const p = Product(
      id: 'p',
      restaurantId: 'r',
      categoryId: 'c',
      name: 'Café',
      priceCents: 1290,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProductView(services: services, args: const ProductArgs(p)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Salvar nos favoritos'));
    await tester.tap(find.text('Salvar nos favoritos'));
    await tester.pumpAndSettle();
    expect((await services.cache.favorites()).single.id, 'p');
    await tester.tap(find.text('Remover dos favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect((await services.cache.favorites()).length, 1);
    await tester.tap(find.text('Remover dos favoritos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(await services.cache.favorites(), isEmpty);
  });
}
