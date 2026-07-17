import 'package:flutter/material.dart';

class SlideInPanel extends StatefulWidget {
  const SlideInPanel({
    super.key,
    required this.child,
    this.width = 300,
    this.onClose,
  });

  final Widget child;
  final double width;
  final VoidCallback? onClose;

  @override
  State<SlideInPanel> createState() => _SlideInPanelState();

  /// 从右侧显示滑入面板
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double width = 300,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SlideInPanel',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SlideInPanelOverlay(
          width: width,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

class _SlideInPanelState extends State<SlideInPanel> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _SlideInPanelOverlay extends StatelessWidget {
  const _SlideInPanelOverlay({
    required this.child,
    required this.width,
  });

  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
