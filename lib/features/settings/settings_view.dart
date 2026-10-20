import 'package:flutter/material.dart';

import '../../shared/widgets/page_frame.dart';
import 'theme_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({required this.viewModel, super.key});
  final ThemeViewModel viewModel;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aparência')),
    body: ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => PageFrame(
        children: [
          Text(
            'Do seu jeito',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Text(
            'Escolha um tema. Sua preferência é mantida ao reabrir o aplicativo.',
          ),
          for (final option in const [
            (ThemeMode.system, 'Sistema', Icons.brightness_auto),
            (ThemeMode.light, 'Claro', Icons.light_mode),
            (ThemeMode.dark, 'Escuro', Icons.dark_mode),
          ])
            Card(
              child: ListTile(
                minTileHeight: 64,
                leading: Icon(option.$3),
                title: Text(option.$2),
                trailing: viewModel.mode == option.$1
                    ? const Icon(Icons.check, semanticLabel: 'Tema selecionado')
                    : null,
                selected: viewModel.mode == option.$1,
                enabled: !viewModel.saving,
                onTap: () => viewModel.change(option.$1),
              ),
            ),
          if (viewModel.saving)
            const LinearProgressIndicator(semanticsLabel: 'Salvando tema'),
          if (viewModel.error case final String message) Text(message),
        ],
      ),
    ),
  );
}
