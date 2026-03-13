import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated Checkmark عند تناول الدواء
class AnimatedCheckmark extends StatefulWidget {
  final bool isChecked;
  final Color color;
  final double size;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    required this.isChecked,
    this.color = Colors.green,
    this.size = 24,
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });

    if (widget.isChecked) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCheckmark oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked && !oldWidget.isChecked) {
      _controller.forward(from: 0);
      // Haptic feedback
      HapticFeedback.mediumImpact();
    } else if (!widget.isChecked && oldWidget.isChecked) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _CheckmarkPainter(
              progress: _checkAnimation.value,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Checkmark path points
    final startPoint = Offset(size.width * 0.2, size.height * 0.5);
    final midPoint = Offset(size.width * 0.4, size.height * 0.7);
    final endPoint = Offset(size.width * 0.8, size.height * 0.3);

    if (progress <= 0.5) {
      // First half - draw from start to mid
      final currentProgress = progress * 2;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(
        startPoint.dx + (midPoint.dx - startPoint.dx) * currentProgress,
        startPoint.dy + (midPoint.dy - startPoint.dy) * currentProgress,
      );
    } else {
      // Second half - draw full first line and partial second
      final currentProgress = (progress - 0.5) * 2;
      path.moveTo(startPoint.dx, startPoint.dy);
      path.lineTo(midPoint.dx, midPoint.dy);
      path.lineTo(
        midPoint.dx + (endPoint.dx - midPoint.dx) * currentProgress,
        midPoint.dy + (endPoint.dy - midPoint.dy) * currentProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Tap Scale Animation Widget
class TapScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleValue;
  final Duration duration;
  final bool enableHaptic;

  const TapScaleWidget({
    super.key,
    required this.child,
    this.onTap,
    this.scaleValue = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.enableHaptic = true,
  });

  @override
  State<TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<TapScaleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Animated Action Button (للـ Take/Skip)
class AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final VoidCallback? onTap;
  final bool showRipple;

  const AnimatedActionButton({
    super.key,
    required this.icon,
    required this.backgroundColor,
    this.iconColor = Colors.white,
    this.size = 44,
    this.onTap,
    this.showRipple = true,
  });

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.9), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    _controller.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Material(
        color: widget.backgroundColor,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: widget.backgroundColor.withOpacity(0.3),
        child: InkWell(
          onTap: _handleTap,
          customBorder: const CircleBorder(),
          splashColor: widget.showRipple 
              ? Colors.white.withOpacity(0.3) 
              : Colors.transparent,
          highlightColor: Colors.transparent,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Icon(
              widget.icon,
              color: widget.iconColor,
              size: widget.size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade In Widget
class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Staggered List Animation
class StaggeredListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration itemDelay;

  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = const Duration(milliseconds: 100),
    this.itemDelay = const Duration(milliseconds: 50),
  });

  @override
  Widget build(BuildContext context) {
    return FadeInWidget(
      delay: baseDelay + (itemDelay * index),
      child: child,
    );
  }
}

/// Success Animation (للـ snackbar أو dialogs)
class SuccessAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    this.size = 60,
    this.color = Colors.green,
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.mediumImpact();
        widget.onComplete?.call();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circle
              Transform.scale(
                scale: _circleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.1),
                    border: Border.all(color: widget.color, width: 2),
                  ),
                ),
              ),
              // Checkmark
              CustomPaint(
                size: Size(widget.size * 0.5, widget.size * 0.5),
                painter: _CheckmarkPainter(
                  progress: _checkAnimation.value,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
