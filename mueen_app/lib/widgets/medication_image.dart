import 'package:flutter/material.dart';

class MedicationImage extends StatelessWidget {
  final String? gtin;
  final double? size;

  const MedicationImage({
    super.key,
    required this.gtin,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (gtin == null || gtin!.trim().isEmpty) {
      return _fallback();
    }

    final cleanGtin = gtin!.replaceAll(RegExp(r'[^0-9]'), '');
    final padded14 = cleanGtin.padLeft(14, '0');

    final paths = [
      'assets/drug_images/$cleanGtin.jpg',
      'assets/drug_images/$cleanGtin.png',
      'assets/drug_images/$padded14.jpg',
      'assets/drug_images/$padded14.png',
    ];

    return _tryLoad(paths, 0);
  }

  Widget _tryLoad(List<String> paths, int index) {
    if (index >= paths.length) {
      return _fallback();
    }

    return Image.asset(
      paths[index],
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _tryLoad(paths, index + 1),
    );
  }

  Widget _fallback() {
    return Icon(
      Icons.medication,
      color: const Color(0xFF16B6C8),
      size: size,
    );
  }
}
