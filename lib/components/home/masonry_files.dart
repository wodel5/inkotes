import 'package:flutter/material.dart';
import 'package:foledge/components/home/preview_card.dart';
import 'package:foledge/data/extensions/flutter_extensions.dart';

class MasonryFiles extends StatefulWidget {
  const MasonryFiles({
    super.key,
    required this.files,
    required this.selectedFiles,
    required this.crossAxisCount,
  });

  final List<String> files;
  final int crossAxisCount;
  final ValueNotifier<List<String>> selectedFiles;

  @override
  State<MasonryFiles> createState() => _MasonryFilesState();
}

class _MasonryFilesState extends State<MasonryFiles> {
  final ValueNotifier<bool> isAnythingSelected = ValueNotifier(false);

  void toggleSelection(String filePath, bool selected) {
    if (selected) {
      widget.selectedFiles.value.add(filePath);
    } else {
      widget.selectedFiles.value.remove(filePath);
    }
    isAnythingSelected.value = widget.selectedFiles.value.isNotEmpty;
    widget.selectedFiles.notifyListenersPlease();
  }

  @override
  Widget build(BuildContext context) {
    isAnythingSelected.value = widget.selectedFiles.value.isNotEmpty;

    final screenWidth = MediaQuery.sizeOf(context).width;
    const horizontalPadding = 16.0 * 2;
    const spacing = 16.0;
    final cardWidth =
        (screenWidth - horizontalPadding - spacing * (widget.crossAxisCount - 1)) /
            widget.crossAxisCount;

    // 缩略图高度 = 卡片宽度 × 0.6
    final thumbnailHeight = cardWidth * PreviewCard.thumbnailAspectRatio;
    // 卡片总高 = 缩略图 + 标题 + 日期
    final cardHeight = thumbnailHeight + PreviewCard.titleHeight + PreviewCard.dateHeight;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= widget.files.length) return const SizedBox.shrink();
            final file = widget.files[index];
            return ValueListenableBuilder(
              valueListenable: isAnythingSelected,
              builder: (context, isAnythingSelected, _) {
                return PreviewCard(
                  filePath: file,
                  toggleSelection: toggleSelection,
                  selected: widget.selectedFiles.value.contains(file),
                  isAnythingSelected: isAnythingSelected,
                  thumbnailHeight: thumbnailHeight,
                );
              },
            );
          },
          childCount: widget.files.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          childAspectRatio: cardWidth / cardHeight,
        ),
      ),
    );
  }
}
