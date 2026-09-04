import 'package:flutter/material.dart';

/// Hosted artwork enables new characters without shipping another asset bundle.
class CharacterImage extends StatelessWidget {
  const CharacterImage({
    super.key,
    required this.asset,
    this.url,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Image.asset(
      asset,
      fit: fit,
      errorBuilder: (context, error, stackTrace) =>
          const Center(child: Icon(Icons.person_rounded)),
    );
    return url == null
        ? fallback()
        : Image.network(
            url!,
            fit: fit,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : fallback(),
            errorBuilder: (context, error, stackTrace) => fallback(),
          );
  }
}
