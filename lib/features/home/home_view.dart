import 'package:flutter/material.dart';

import '../../shared/widgets/page_frame.dart';

class HomeView extends StatelessWidget {
  const HomeView({required this.onSettings, super.key});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simples QR'),
        actions: [
          IconButton(
            onPressed: onSettings,
            tooltip: 'Configurações de aparência',
            icon: const Icon(Icons.contrast),
          ),
        ],
      ),
      body: PageFrame(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.qr_code_2,
                    size: 72,
                    color: theme.colorScheme.primary,
                    semanticLabel: 'Cardápio por QR code',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'O cardápio,\nna palma da mão.',
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Consulte pratos, ingredientes e preços pelo celular.',
                  ),
                ],
              ),
            ),
          ),
          Text(
            'Seu próximo sabor começa aqui',
            style: theme.textTheme.titleLarge,
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 48,
                    semanticLabel: 'Cardápio ainda não conectado',
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Nenhum cardápio conectado',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Esta é a base da Sprint 0. A consulta aos restaurantes e a leitura de QR code serão integradas nas próximas sprints.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onSettings,
            icon: const Icon(Icons.palette_outlined),
            label: const Text('Personalizar aparência'),
          ),
        ],
      ),
    );
  }
}
