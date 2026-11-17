import 'package:flutter/material.dart';

import 'menu_photo.dart';

class MenuHeader extends StatelessWidget {
  const MenuHeader({
    required this.title,
    required this.description,
    this.coverUrl,
    this.logoUrl,
    super.key,
  });

  final String title, description;
  final String? coverUrl, logoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colors.primaryContainer, colors.tertiaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (coverUrl != null)
              MenuPhoto(url: coverUrl, height: 210, label: 'Capa do cardápio'),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (logoUrl != null) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: MenuPhoto(
                          url: logoUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                          label: 'Logo de $title',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  if (description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
