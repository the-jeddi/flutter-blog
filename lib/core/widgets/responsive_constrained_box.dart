import 'package:flutter/material.dart';

class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  // Set max width to 700 for better desktop experience
  final double maxWidth;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth = 700,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
