import 'package:flutter/material.dart';

class ExportButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const ExportButton({
    super.key,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: const Icon(Icons.download, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }
}