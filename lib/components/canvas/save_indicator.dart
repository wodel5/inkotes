import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:foledge/components/theming/adaptive_circular_progress_indicator.dart';
import 'package:foledge/data/is_this_a_test.dart';
import 'package:foledge/data/routes.dart';

/// Replaces the back button as the
/// [AppBar.leading] widget in the [AppBar]
/// to indicate the state of saving in the editor.
class SaveIndicator extends StatelessWidget {
  const SaveIndicator({
    super.key,
    required this.savingState,
    required this.triggerSave,
  });

  final ValueNotifier<SavingState> savingState;
  final VoidCallback triggerSave;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: savingState,
      builder: (context, isSaving, _) {
        return AnimatedSwitcher(
          duration: isThisATest
              ? Duration.zero
              : const Duration(milliseconds: 300),
          child: IconButton(
            key: ValueKey(savingState.value),
            onPressed: () => _onPressed(context),
            icon: switch (savingState.value) {
              .waitingToSave => const Icon(Icons.save),
              .saving => const AdaptiveCircularProgressIndicator(),
              .saved => const Icon(Icons.arrow_back),
            },
          ),
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    switch (savingState.value) {
      case .waitingToSave:
        triggerSave();
      case .saving:
        break;
      case .saved:
        _back(context);
    }
  }

  void _back(BuildContext context) {
    final navigator = Navigator.of(context);
    final isWhiteboard = !navigator.canPop();
    if (isWhiteboard) {
      context.go(RoutePaths.home);
    } else {
      navigator.pop();
    }
  }
}

enum SavingState { waitingToSave, saving, saved }
