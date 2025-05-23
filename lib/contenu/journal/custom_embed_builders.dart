import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class CustomStyledImageBuilder implements EmbedBuilder {
  @override
  bool get expanded => false;

  @override
  String get key => 'image';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final node = embedContext.node;
    if (node.value.type != 'image') return const SizedBox.shrink();

    final imageUrl = node.value.data;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth.clamp(0, 700).toDouble();

          return Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover, // ✅ comme object-fit: cover
                alignment: Alignment.center,
                width: maxWidth,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: maxWidth,
                    height: 200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                const Text("❌ Erreur lors du chargement de l’image"),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: widget,
    );
  }

  @override
  String toPlainText(Embed node) => '[Image]';
}
