import 'dart:typed_data';

import 'package:flutter/material.dart';

class MenuPhoto extends StatelessWidget {
  const MenuPhoto({
    this.url,
    this.bytes,
    this.width,
    this.height = 200,
    this.label = 'Foto do cardápio',
    this.fit = BoxFit.cover,
    super.key,
  });
  final String? url;
  final Uint8List? bytes;
  final double? width;
  final double height;
  final String label;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.restaurant_outlined, size: 32)),
    );
    final decodeWidth =
        ((width ?? 600) * MediaQuery.devicePixelRatioOf(context)).round().clamp(
          1,
          1200,
        );
    Widget content = fallback;
    if (bytes != null) {
      content = Image.memory(
        bytes!,
        fit: fit,
        cacheWidth: decodeWidth,
        errorBuilder: (_, _, _) => fallback,
      );
    } else if (url != null && url!.isNotEmpty) {
      content = Image.network(
        url!,
        fit: fit,
        cacheWidth: decodeWidth,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Stack(
                alignment: Alignment.center,
                children: [
                  fallback,
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
      );
    }
    return Semantics(
      label: label,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(width: width, height: height, child: content),
      ),
    );
  }
}
