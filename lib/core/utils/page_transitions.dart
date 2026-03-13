import 'package:flutter/material.dart';

/// Page Transitions المشتركة للتطبيق
class AppPageTransitions {
  /// Fade + Slide Transition (الافتراضي)
  static Route<T> fadeSlide<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  /// Slide from Right (للتنقل للأمام)
  static Route<T> slideRight<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Slide from Bottom (للـ Bottom Sheets و Dialogs)
  static Route<T> slideUp<T>(Widget page, {String? name, bool fullscreen = false}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      opaque: fullscreen,
      barrierColor: fullscreen ? null : Colors.black54,
      barrierDismissible: !fullscreen,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  /// Scale + Fade (للـ Dialogs)
  static Route<T> scaleFade<T>(Widget page, {String? name}) {
    return PageRouteBuilder<T>(
      settings: RouteSettings(name: name),
      opaque: false,
      barrierColor: Colors.black54,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 250),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}

/// Extension للتنقل السهل
extension NavigatorExtension on BuildContext {
  /// Navigate with fade + slide
  Future<T?> pushFadeSlide<T>(Widget page) {
    return Navigator.of(this).push<T>(AppPageTransitions.fadeSlide(page));
  }

  /// Navigate with slide from right
  Future<T?> pushSlideRight<T>(Widget page) {
    return Navigator.of(this).push<T>(AppPageTransitions.slideRight(page));
  }

  /// Navigate with slide from bottom
  Future<T?> pushSlideUp<T>(Widget page, {bool fullscreen = false}) {
    return Navigator.of(this).push<T>(
      AppPageTransitions.slideUp(page, fullscreen: fullscreen),
    );
  }

  /// Replace with fade + slide
  Future<T?> replaceFadeSlide<T>(Widget page) {
    return Navigator.of(this).pushReplacement<T, void>(
      AppPageTransitions.fadeSlide(page),
    );
  }
}
