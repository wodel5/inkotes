import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/common/dock_button.dart';
import 'package:inkotes/components/home/preview_card.dart';
import 'package:inkotes/components/theming/adaptive_alert_dialog.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/pages/editor/editor.dart';
import 'package:inkotes/pages/home/widgets/trash_card.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<String> _trashedFiles = [];
  bool _isLoading = true;
  final List<String> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadTrashedFiles();
  }

  Future<void> _loadTrashedFiles() async {
    setState(() => _isLoading = true);
    final files = await FileManager.getTrashedFiles();
    if (mounted) {
      setState(() {
        _trashedFiles = files;
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String filePath) {
    setState(() {
      if (_selectedFiles.contains(filePath)) {
        _selectedFiles.remove(filePath);
      } else {
        _selectedFiles.add(filePath);
      }
    });
  }

  bool get _isAnythingSelected => _selectedFiles.isNotEmpty;

  Future<void> _restoreSelected() async {
    for (final file in _selectedFiles) {
      await FileManager.restoreFromTrash(file);
    }
    setState(() => _selectedFiles.clear());
    await _loadTrashedFiles();
  }

  Future<void> _deleteSelected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.home.trash.confirmPermanentDelete),
        content: const SizedBox.shrink(),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t.common.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t.home.trash.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final file in _selectedFiles) {
        await FileManager.deleteFile(file + Editor.extension);
      }
      setState(() => _selectedFiles.clear());
      await _loadTrashedFiles();
    }
  }

  void _selectAll() {
    setState(() {
      if (_selectedFiles.length == _trashedFiles.length) {
        _selectedFiles.clear();
      } else {
        _selectedFiles.clear();
        _selectedFiles.addAll(_trashedFiles);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > MediaQuery.sizeOf(context).height;
    const horizontalPadding = 16.0 * 2;
    const spacing = 16.0;
    final crossAxisCount = isLandscape ? 4 : 2;
    final cardWidth =
        (screenWidth - horizontalPadding - spacing * (crossAxisCount - 1)) /
            crossAxisCount;

    final thumbnailHeight = cardWidth * PreviewCard.thumbnailAspectRatio;
    final cardHeight = thumbnailHeight + PreviewCard.titleHeight + PreviewCard.dateHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.home.trash.title),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trashedFiles.isEmpty
                    ? _buildEmptyState()
                    : GestureDetector(
                        onTap: _isAnythingSelected
                            ? () => setState(() => _selectedFiles.clear())
                            : null,
                        behavior: HitTestBehavior.translucent,
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                              sliver: SliverGrid(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final file = _trashedFiles[index];
                                    return TrashCard(
                                      filePath: file,
                                      thumbnailHeight: thumbnailHeight,
                                      selected: _selectedFiles.contains(file),
                                      isAnythingSelected: _isAnythingSelected,
                                      onToggleSelection: () => _toggleSelection(file),
                                    );
                                  },
                                  childCount: _trashedFiles.length,
                                ),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: spacing,
                                  crossAxisSpacing: spacing,
                                  childAspectRatio: cardWidth / cardHeight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AnimatedSlide(
                offset: _isAnythingSelected ? Offset.zero : const Offset(0, 1),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _isAnythingSelected ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_isAnythingSelected,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: IntrinsicWidth(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DockButton(
                                      icon: FontAwesomeIcons.rotateLeft,
                                      onPressed: _restoreSelected,
                                    ),
                                    DockButton(
                                      icon: FontAwesomeIcons.trash,
                                      onPressed: _deleteSelected,
                                    ),
                                    DockButton(
                                      icon: FontAwesomeIcons.checkDouble,
                                      selected: _selectedFiles.isNotEmpty && _selectedFiles.length == _trashedFiles.length,
                                      onPressed: _selectAll,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t.home.trash.empty,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              t.home.trash.emptyDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
