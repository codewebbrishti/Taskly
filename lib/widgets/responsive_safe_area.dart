import 'package:flutter/material.dart';

/// SafeArea that also keeps content to a readable width on tablets and
/// landscape screens. On normal phones it fills the whole width.
class ResponsiveSafeArea extends StatelessWidget {
  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.maxWidth = 600,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < maxWidth
              ? constraints.maxWidth
              : maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
