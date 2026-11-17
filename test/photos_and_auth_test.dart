import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:simples_qr/data/remote/photo_repository.dart';
import 'package:simples_qr/data/remote/catalog_repository.dart';
import 'package:simples_qr/domain/catalog.dart';
import 'package:simples_qr/features/auth/auth_view_model.dart';
import 'package:simples_qr/shared/widgets/menu_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foto valida conteúdo e limite antes de enviar', () {
    expect(
      SelectedPhoto.fromBytes(Uint8List.fromList([255, 216, 255, 0]))
          .contentType,
      'image/jpeg',
    );
    expect(
      () => SelectedPhoto.fromBytes(Uint8List(SelectedPhoto.maxBytes + 1)),
      throwsFormatException,
    );
    expect(
      () => SelectedPhoto.fromBytes(
        Uint8List.fromList(utf8.encode('<svg></svg>')),
      ),
      throwsFormatException,
    );
    expect(() => SelectedPhoto.fromBytes(Uint8List(0)), throwsFormatException);
  });

  test('cache antigo continua legível e foto permanece no novo cache', () {
    final old = {
      'id': 'p',
      'restaurant_id': 'r',
      'category_id': 'c',
      'name': 'Produto',
      'price_cents': 1200,
    };
    expect(Product.fromMap(old).imageUrl, isNull);
    final product = Product.fromMap({
      ...old,
      'image_url': 'https://example.com/foto.jpg',
    });
    expect(Product.fromJson(product.toJson()).imageUrl, product.imageUrl);
    const restaurant = Restaurant(
      id: 'r',
      ownerId: 'u',
      name: 'Restaurante',
      slug: 'teste',
      imageUrl: 'https://example.com/capa.jpg',
    );
    expect(
      Restaurant.fromJson(restaurant.toJson()).imageUrl,
      restaurant.imageUrl,
    );
  });

  test(
    'cadastro pendente permite reenvio e impede cliques duplicados',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/signup')) {
            return http.Response(
              jsonEncode({
                'id': 'u',
                'aud': 'authenticated',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-01-01T00:00:00Z',
              }),
              200,
            );
          }
          return http.Response('{}', 200);
        }),
      );
      final model = AuthViewModel(client);
      expect(
        await model.submit(
          AuthMode.register,
          ' usuario@example.com ',
          'password123',
        ),
        isFalse,
      );
      expect(model.needsConfirmation, isTrue);
      expect(model.resendSeconds, 60);
      await model.resendConfirmation('usuario@example.com');
      expect(requests.length, 1);
      model.resendSeconds = 0;
      await model.resendConfirmation('usuario@example.com');
      expect(requests.last.url.path, '/auth/v1/resend');
      expect(jsonDecode(requests.last.body)['type'], 'signup');
      expect(model.busy, isFalse);
      model.dispose();
      await client.dispose();
    },
  );

  test('falha SMTP encerra espera e mostra mensagem útil', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'code': 'email_address_not_authorized',
            'msg': 'Email address not authorized',
          }),
          400,
        ),
      ),
    );
    final model = AuthViewModel(client);
    expect(
      await model.submit(
        AuthMode.register,
        'usuario@example.com',
        'password123',
      ),
      isFalse,
    );
    expect(model.busy, isFalse);
    expect(model.error, contains('serviço de e-mail'));
    expect(model.message, isNull);
    model.dispose();
    await client.dispose();
  });

  test('erro de rede não expõe URL técnica nem acusa senha', () {
    final message = friendlyError(
      const AuthException(
        'ClientException: Failed to fetch, uri=https://example.com/signup',
      ),
    );
    expect(message, contains('conectar'));
    expect(message, isNot(contains('https://')));
  });

  testWidgets('imagem inválida exibe alternativa sem quebrar a tela', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MenuPhoto(bytes: Uint8List.fromList([1, 2, 3]))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
