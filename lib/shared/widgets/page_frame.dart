import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTokens.contentWidth),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppTokens.spacing),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppTokens.spacing),
          itemBuilder: (_, index) => children[index],
        ),
      ),
    ),
  );
}
