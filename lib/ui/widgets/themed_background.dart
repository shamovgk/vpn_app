import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;
  final bool safeArea;
  const ThemedBackground({super.key, required this.child, this.safeArea = true});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget content = Container(
      decoration: BoxDecoration(
        color: colors.bg,
        image: const DecorationImage(
          image: AssetImage('assets/background.png'),
          fit: BoxFit.fitWidth,
          opacity: 0.3,
          alignment: Alignment(0, -0.1),
        ),
      ),
      child: child,
    );

    return safeArea ? SafeArea(child: content) : content;
  }
}
