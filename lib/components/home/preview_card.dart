import 'dart:async';

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:inkotes/components/canvas/inner_canvas.dart';
import 'package:inkotes/components/common/fallback_thumbnail.dart';
import 'package:inkotes/data/extensions/collection_extensions.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/data/is_this_a_test.dart';
import 'package:inkotes/data/routes.dart';
import 'package:inkotes/pages/editor/editor.dart';
import 'package:yaru/yaru.dart';

class PreviewCard extends StatefulWidget {
  PreviewCard({
    required this.filePath,
    required this.toggleSelection,
    required this.selected,
    required this.isAnythingSelected,
    required this.thumbnailHeight,
  }) : super(key: ValueKey('PreviewCard$filePath'));

  final String filePath;
  final bool selected;
  final bool isAnythingSelected;
  final void Function(String, bool) toggleSelection;
  final double thumbnailHeight;

  static const double titleHeight = 48;
  static const double dateHeight = 24;
  static const double thumbnailAspectRatio = 0.6; // width:height

  @override
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  final expanded = ValueNotifier(false);
  final thumbnail = _ThumbnailState();

  @override
  void initState() {
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );

    expanded.value = widget.selected;
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final imageFile = FileManager.getFile(
      '${widget.filePath}${Editor.extension}.p',
    );
    if (isThisATest) {
      thumbnail.image = imageFile.existsSync()
          ? MemoryImage(imageFile.readAsBytesSync())
          : null;
    } else {
      thumbnail.image = FileImage(imageFile);
    }
  }

  @override
  void didUpdateWidget(covariant PreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      expanded.value = widget.selected;
    }
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    if (event.filePath != widget.filePath) return;
    if (event.type == .delete) {
      thumbnail.image = null;
    } else if (event.type == .write) {
      thumbnail.image?.evict();
      thumbnail.markAsChanged();
    } else {
      throw Exception('Unknown file operation type: ${event.type}');
    }
  }

  void _toggleCardSelection() {
    expanded.value = !expanded.value;
    widget.toggleSelection(widget.filePath, expanded.value);
  }

  Timer? _refreshThumbnailTimer;
  void _refreshThumbnailAfterDelay() {
    _refreshThumbnailTimer?.cancel();
    _refreshThumbnailTimer = Timer(const Duration(milliseconds: 500), () {
      thumbnail.image?.evict();
      thumbnail.markAsChanged();
    });
  }

  String _formatEditedDate() {
    final file = FileManager.getFile('${widget.filePath}${Editor.extension}');
    if (!file.existsSync()) return '';

    final modified = file.lastModifiedSync();
    return formatEditedDate(modified);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final transitionDuration = Duration(
      milliseconds: disableAnimations ? 0 : 300,
    );

    // 缩略图：固定 0.6:1 宽高比
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
            ListenableBuilder(
              listenable: thumbnail,
              builder: (context, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ConstrainedBox(
                  key: ValueKey(thumbnail.updateCount),
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    minHeight: 100,
                  ),
                  child: thumbnail.doesImageExist
                      ? Image(
                          image: thumbnail.image!,
                          alignment: Alignment.topCenter,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const FallbackThumbnail();
                          },
                        )
                      : const FallbackThumbnail(),
                ),
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder(
                valueListenable: expanded,
                builder: (context, expanded, child) => AnimatedOpacity(
                  opacity: expanded ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !expanded,
                    child: child!,
                  ),
                ),
                child: GestureDetector(
                  onTap: _toggleCardSelection,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // 标题：固定 2 行高（48px），文字居中
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

    // 日期：固定 1 行高（24px），文字居中
    final dateWidget = SizedBox(
      height: PreviewCard.dateHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _formatEditedDate(),
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

    final Widget card = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Column(
        children: [
          thumbnailWidget,
          titleWidget,
          dateWidget,
        ],
      ),
    );

    return GestureDetector(
      onTap: widget.isAnythingSelected ? _toggleCardSelection : null,
      onSecondaryTap: _toggleCardSelection,
      onLongPress: _toggleCardSelection,
      behavior: HitTestBehavior.opaque,
      child: ValueListenableBuilder(
        valueListenable: expanded,
        builder: (context, expanded, _) {
          return IgnorePointer(
            ignoring: widget.isAnythingSelected,
            child: OpenContainer(
              clipBehavior: Clip.none,
              closedColor: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFE8EAED)
                  : const Color(0xFF111115),
              closedShape: RoundedRectangleBorder(
                side: BorderSide(
                  color: expanded
                      ? colorScheme.primary
                      : Theme.of(context).brightness == Brightness.light
                          ? const Color(0xFFD0D5DD)
                          : const Color(0xFF2C2C2E),
                  width: kYaruFocusBorderWidth,
                ),
                borderRadius: const .all(.circular(kYaruContainerRadius)),
              ),
              closedElevation: 0,
              closedBuilder: (context, action) => card,
              openColor: colorScheme.surface,
              openBuilder: (context, action) => Editor(path: widget.filePath),
              transitionDuration: transitionDuration,
              routeSettings: RouteSettings(
                name: RoutePaths.editFilePath(widget.filePath),
              ),
              onClosed: (_) => _refreshThumbnailAfterDelay(),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _refreshThumbnailTimer?.cancel();
    fileWriteSubscription?.cancel();
    super.dispose();
  }
}

class _ThumbnailState extends ChangeNotifier {
  var updateCount = 0;
  ImageProvider? _image;

  void markAsChanged() {
    ++updateCount;
    notifyListeners();
  }

  ImageProvider? get image => _image;
  set image(ImageProvider? image) {
    _image = image;
    markAsChanged();
  }

  bool get doesImageExist => switch (image) {
        (final FileImage fileImage) =>
          fileImage.file.existsSync() && fileImage.file.lengthSync() > 0,
        null => false,
        _ => true,
      };
}
