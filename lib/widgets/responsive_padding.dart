import 'package:flutter/material.dart';

class ResponsivePadding extends StatelessWidget {
  final Widget child;

  const ResponsivePadding({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double horizontalPadding;

    if (width < 375) {
      horizontalPadding = 16;
    } else if (width < 600) {
      horizontalPadding = 24;
    } else if (width < 900) {
      horizontalPadding = 48;
    } else {
      horizontalPadding = width * 0.2;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: child,
    );
  }
}
