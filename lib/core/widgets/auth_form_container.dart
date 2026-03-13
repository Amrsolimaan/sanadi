import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AuthFormContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const AuthFormContainer({
    super.key,
    required this.child,
    this.padding,
  });

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    final isLarge = _isLargeScreen(context);

    if (isLarge) {
      return child;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      ),
    );
  }
}
