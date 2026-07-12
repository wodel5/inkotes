import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:foledge/components/files/file_tree.dart';
import 'package:foledge/components/theming/adaptive_icon.dart';

class VerticalNavbar extends HookWidget {
  const VerticalNavbar({
    super.key,
    required this.destinations,
    this.selectedIndex = 0,
    this.onDestinationSelected,
  });

  final List<NavigationRailDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final expanded = useState(false);

    final theme = Theme.of(context);
    final backgroundColor = theme.colorScheme.surfaceContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const SizedBox(height: kToolbarHeight),
          Padding(
            padding: const .symmetric(vertical: 10, horizontal: 12),
            child: TextButton(
              onPressed: () => expanded.value = !expanded.value,
              child: AdaptiveIcon(
                icon: expanded.value ? Icons.chevron_left : Icons.chevron_right,
              ),
            ),
          ),
          IntrinsicHeight(
            child: NavigationRail(
              destinations: destinations,
              selectedIndex: selectedIndex,
              backgroundColor: backgroundColor,
              extended: expanded.value,
              minExtendedWidth: 300,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
          if (expanded.value) const Expanded(child: FileTree()),
        ],
      ),
    );
  }
}
