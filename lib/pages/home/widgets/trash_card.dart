import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';
import 'package:inkotes/components/canvas/inner_canvas.dart';
import 'package:inkotes/components/common/fallback_thumbnail.dart';
import 'package:inkotes/components/home/preview_card.dart';
import 'package:inkotes/data/extensions/collection_extensions.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/pages/editor/editor.dart';

class TrashCard extends StatefulWidget {
  const TrashCard({
    super.key,
    required this.filePath,
    required this.thumbnailHeight,
    required this.selected,
    required this.isAnythingSelected,
    required this.onToggleSelection,
  });

  final String filePath;
  final double thumbnailHeight;
  final bool selected;
  final bool isAnythingSelected;
  final VoidCallback onToggleSelection;

  @override
  State<TrashCard> createState() => _TrashCardState();
}

class _TrashCardState extends State<TrashCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant TrashCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      setState(() => _expanded = widget.selected);
    }
  }

  String _formatDate() {
    final file = FileManager.getFile('${widget.filePath}${Editor.extension}');
    if (!file.existsSync()) return '';

    final modified = file.lastModifiedSync();
    return formatEditedDate(modified);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    final thumbnailWidget = SizedBox(
      height: widget.thumbnailHeight,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(kYaruContainerRadius),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: ColoredBox(
                color: InnerCanvas.defaultBackgroundColor,
              ),
            ),
            Builder(
              builder: (context) {
                final imageFile = FileManager.getFile(
                  '${widget.filePath}${Editor.extension}.p',
                );
                if (imageFile.existsSync()) {
                  return Image(
                    image: FileImage(imageFile),
                    alignment: Alignment.topCenter,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const FallbackThumbnail();
                    },
                  );
                }
                return const FallbackThumbnail();
              },
            ),
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _expanded ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_expanded,
                  child: GestureDetector(
                    onTap: widget.onToggleSelection,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final titleWidget = SizedBox(
      height: PreviewCard.titleHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            widget.filePath.substring(widget.filePath.lastIndexOf('/') + 1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    final dateWidget = SizedBox(
      height: PreviewCard.dateHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _formatDate(),
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: widget.isAnythingSelected ? widget.onToggleSelection : null,
      onLongPress: widget.onToggleSelection,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: brightness == Brightness.light
            ? const Color(0xFFE8EAED)
            : const Color(0xFF111115),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: _expanded
                ? colorScheme.primary
                : brightness == Brightness.light
                    ? const Color(0xFFD0D5DD)
                    : const Color(0xFF2C2C2E),
            width: kYaruFocusBorderWidth,
          ),
          borderRadius: const BorderRadius.all(
            Radius.circular(kYaruContainerRadius),
          ),
        ),
        child: Column(
          children: [
            thumbnailWidget,
            titleWidget,
            dateWidget,
          ],
        ),
      ),
    );
  }
}
