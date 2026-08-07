import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/common/dock_button.dart';
import 'package:inkotes/components/common/glassmorphism_dock.dart';
import 'package:inkotes/data/file_manager/file_trash_manager.dart';
import 'package:inkotes/i18n/strings.g.dart';

/// Bottom dock for the home page with rename and action buttons.
class HomeBottomDock extends StatelessWidget {
  const HomeBottomDock({
    super.key,
    required this.selectedFiles,
    required this.filePaths,
    required this.isRenaming,
    required this.renameController,
    required this.renameError,
    required this.onStartRename,
    required this.onCancelRename,
    required this.onConfirmRename,
  });

  final ValueNotifier<List<String>> selectedFiles;
  final List<String> filePaths;
  final bool isRenaming;
  final TextEditingController renameController;
  final String? renameError;
  final VoidCallback onStartRename;
  final VoidCallback onCancelRename;
  final VoidCallback onConfirmRename;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedSlide(
        offset: selectedFiles.value.isEmpty ? const Offset(0, 1) : Offset.zero,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: selectedFiles.value.isEmpty ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: selectedFiles.value.isEmpty,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: GlassmorphismDock(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Rename editor row
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOut,
                        child: isRenaming
                            ? _buildRenameEditor(context)
                            : const SizedBox.shrink(),
                      ),
                      // Action buttons row
                      IntrinsicWidth(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DockButton(
                              icon: FontAwesomeIcons.penToSquare,
                              selected: isRenaming,
                              enabled: selectedFiles.value.length == 1,
                              onPressed: selectedFiles.value.length == 1
                                  ? onStartRename
                                  : null,
                            ),
                            DockButton(
                              icon: FontAwesomeIcons.trash,
                              onPressed: () async {
                                onCancelRename();
                                for (final file in selectedFiles.value) {
                                  await FileTrashManager.markAsTrashed(file);
                                }
                                selectedFiles.value = [];
                              },
                            ),
                            DockButton(
                              icon: FontAwesomeIcons.checkDouble,
                              selected: selectedFiles.value.isNotEmpty &&
                                  selectedFiles.value.length == filePaths.length,
                              onPressed: () {
                                onCancelRename();
                                if (selectedFiles.value.length == filePaths.length) {
                                  selectedFiles.value = [];
                                } else {
                                  selectedFiles.value = List.from(filePaths);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRenameEditor(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SizedBox(
        width: 280,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: renameController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onConfirmRename(),
                style: TextStyle(
                  color: ColorScheme.of(context).onSurface,
                ),
                decoration: InputDecoration(
                  hintText: t.home.renameNote.noteName,
                  errorText: renameError,
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  hintStyle: TextStyle(
                    color: ColorScheme.of(context).onSurface.withValues(alpha: 0.4),
                  ),
                  errorStyle: TextStyle(
                    fontSize: 12,
                    color: ColorScheme.of(context).error,
                  ),
                ),
              ),
            ),
            Tooltip(
              message: t.home.renameNote.rename,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onConfirmRename,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: ColorScheme.of(context).primary,
                  ),
                ),
              ),
            ),
            Tooltip(
              message: t.common.cancel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCancelRename,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.close,
                    size: 20,
                    color: ColorScheme.of(context).onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
