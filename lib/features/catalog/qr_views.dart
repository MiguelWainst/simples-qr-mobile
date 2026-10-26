import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_services.dart';
import '../../domain/catalog.dart';
import '../../shared/widgets/catalog_widgets.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});
  @override
  State<ScannerView> createState() => _ScannerViewState();
}
class _ScannerViewState extends State<ScannerView> {
  final _controller = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  bool _opened = false;
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  void _detect(BarcodeCapture capture) {
    if (_opened) { return; }
    for (final barcode in capture.barcodes) {
      final code = Rules.menuCode(barcode.rawValue ?? '');
      if (code == null) { continue; }
      _opened = true;
      Navigator.pushReplacementNamed(context, '/menu', arguments: MenuArgs(code));
      return;
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Ler QR code')),
    body: Column(children: [
      const Padding(padding: EdgeInsets.all(20), child: Text('Aponte a câmera para o QR code do Simples QR.')),
      Expanded(child: MobileScanner(controller: _controller, onDetect: _detect,
        errorBuilder: (context, error) => const EmptyState('Não foi possível abrir a câmera. Permita o acesso nas configurações do navegador ou aparelho. Você também pode digitar o código na tela inicial.'))),
      Padding(padding: const EdgeInsets.all(16), child: TextButton(
        onPressed: () => Navigator.pop(context), child: const Text('Voltar e digitar o código'))),
    ]));
}
class RestaurantQrView extends StatelessWidget {
  const RestaurantQrView({required this.restaurant, super.key});
  final Restaurant restaurant;
  @override
  Widget build(BuildContext context) {
    const configuredBase = String.fromEnvironment('PUBLIC_APP_URL');
    final base = configuredBase.isNotEmpty ? configuredBase
      : kIsWeb ? Uri.base.replace(query: '', fragment: '').toString() : '';
    final link = base.isEmpty ? null : Uri.parse(base).replace(queryParameters: {'menu': restaurant.slug}, fragment: '').toString();
    return Scaffold(appBar: AppBar(title: const Text('QR do cardápio')), body: ContentWidth(
      child: ListView(padding: const EdgeInsets.all(24), children: [
        SectionTitle(restaurant.name),
        if (!restaurant.published) const Notice('Este restaurante está em rascunho. Publique antes de compartilhar.'),
        if (link == null) const Notice('O QR abaixo contém o código para o leitor do Simples QR. Configure PUBLIC_APP_URL para gerar um link que abre no navegador.'),
        if (link != null && (Uri.parse(link).host == 'localhost' || Uri.parse(link).host == '127.0.0.1'))
          const Notice('Este endereço é local. Para abrir em outro celular, publique o app em HTTPS.'),
        Center(child: Container(color: Colors.white, padding: const EdgeInsets.all(16),
          child: QrImageView(data: link ?? restaurant.slug, size: 240,
            semanticsLabel: 'QR code do restaurante ${restaurant.name}'))),
        const SizedBox(height: 20), SelectableText(link ?? restaurant.slug, textAlign: TextAlign.center),
        TextButton.icon(onPressed: () async {
          await Clipboard.setData(ClipboardData(text: link ?? restaurant.slug));
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copiado.'))); }
        }, icon: const Icon(Icons.copy), label: const Text('Copiar endereço ou código')),
      ])));
  }
}
