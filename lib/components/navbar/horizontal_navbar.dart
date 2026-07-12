import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:foledge/components/navbar/responsive_navbar.dart';

class HorizontalNavbar extends StatelessWidget {
  const HorizontalNavbar({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  final List<NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  /// The height that should be cleared at the bottom of the screen,
  /// excluding padding/safe area, to avoid overlapping the navbar.
  static double clearanceHeightOf(BuildContext context) {
    if (ResponsiveNavbar.isLargeScreen) return 0;
    MediaQuery.sizeOf(context); // ensure context is listening to size changes
    return 64.0 + 16 + 16 - 8; // -8 for toolbar padding
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const .all(16),
        child: Align(
          alignment: AlignmentDirectional.bottomEnd,
          child: GlassyContainer(
            child: Padding(
              padding: const .all(8),
              child: Semantics(
                role: SemanticsRole.tabBar,
                explicitChildNodes: true,
                container: true,
                child: Row(
                  mainAxisSize: .min,
                  spacing: 4,
                  children: [
                    for (int i = 0; i < destinations.length; i++)
                      MergeSemantics(
                        child: Semantics(
                          role: SemanticsRole.tab,
                          selected: i == selectedIndex,
                          child: _ToolbarButton(
                            destination: destinations[i],
                            selected: i == selectedIndex,
                            select: () {
                              onDestinationSelected?.call(i);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassyContainer extends StatelessWidget {
  const GlassyContainer({
    super.key,
    required this.child,
    this.height,
    this.borderRadius,
  });
  final Widget child;
  final double? height;
  final BorderRadius? borderRadius;
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final height = this.height ?? 64.0;
    final borderRadius = this.borderRadius ?? .circular(height / 2);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.5),
              spreadRadius: -1,
              blurRadius: 4,
              offset: const Offset(0, 1),
              blurStyle: BlurStyle.normal,
            ),
          ],
        ),
        child: ClipRRect(
          clipBehavior: Clip.none,
          borderRadius: borderRadius,
          child: Material(
            type: MaterialType.transparency,
            color: Colors.transparent,
            elevation: 3,
            shadowColor: Colors.white,
            borderRadius: borderRadius,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.destination,
    required this.selected,
    this.select,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback? select;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    const borderRadius = BorderRadius.all(.circular(32));
    final selectedBgColor = colorScheme.surface;
    final bgColor = selected ? selectedBgColor : Colors.transparent;
    final fgColor = selected
        ? colorScheme.onSurface
        : colorScheme.onPrimaryContainer;
    return AspectRatio(
      aspectRatio: 1.4,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
        child: InkWell(
          borderRadius: borderRadius,
          onTap: select,
          hoverColor: selectedBgColor.withValues(
            alpha: selectedBgColor.a * 0.5,
          ),
          focusColor: selectedBgColor.withValues(
            alpha: selectedBgColor.a * 0.7,
          ),
          splashColor: colorScheme.primary.withValues(alpha: 0.5),
          child: Column(
            mainAxisAlignment: .center,
            children: [
              Flexible(
                flex: 7,
                child: IconTheme.merge(
                  data: IconThemeData(color: fgColor),
                  child: destination.icon,
                ),
              ),
              Flexible(
                flex: 3,
                child: Text(
                  destination.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: .w500,
                    height: 1,
                    overflow: .clip,
                    color: fgColor,
                  ),
                  textAlign: .center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
