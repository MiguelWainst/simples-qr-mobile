import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simples_qr/app.dart';
import 'package:simples_qr/data/local/preferences_repository.dart';
import 'package:simples_qr/features/settings/theme_view_model.dart';

void main() {
  test('Preferência de tema persiste entre ViewModels', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = PreferencesRepository(
      await SharedPreferences.getInstance(),
    );
    final model = ThemeViewModel(repository);
    await model.change(ThemeMode.dark);
    expect(ThemeViewModel(repository).mode, ThemeMode.dark);
    model.dispose();
  });

  testWidgets('Navega para aparência em tela pequena e fonte ampliada', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final model = ThemeViewModel(
      PreferencesRepository(await SharedPreferences.getInstance()),
    );
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      model.dispose();
    });
    await tester.pumpWidget(SimplesQrApp(theme: model));
    expect(find.text('Simples QR'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Configurações de aparência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(model.mode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });
}
