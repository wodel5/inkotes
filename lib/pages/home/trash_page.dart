import 'package:flutter/material.dart';
import 'package:foledge/components/canvas/inner_canvas.dart';
import 'package:foledge/components/home/preview_card.dart';
import 'package:foledge/data/file_manager/file_manager.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:foledge/pages/editor/editor.dart';
import 'package:yaru/yaru.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<String> _trashedFiles = [];
  bool _isLoading = true;

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

    // 与主页 MasonryFiles 完全一致
    final thumbnailHeight = cardWidth * PreviewCard.thumbnailAspectRatio;
    final cardHeight = thumbnailHeight + PreviewCard.titleHeight + PreviewCard.dateHeight;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.home.trash.title),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trashedFiles.isEmpty
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final file = _trashedFiles[index];
                            return _TrashCard(
                              filePath: file,
                              thumbnailHeight: thumbnailHeight,
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

/// 与主页 PreviewCard 完全一致的卡片
class _TrashCard extends StatelessWidget {
  const _TrashCard({
    required this.filePath,
    required this.thumbnailHeight,
  });

  final String filePath;
  final double thumbnailHeight;

  String _formatEditedDate() {
    final file = FileManager.getFile('${filePath}${Editor.extension}');
    if (!file.existsSync()) return '';

    final modified = file.lastModifiedSync();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final modifiedDay = DateTime(modified.year, modified.month, modified.day);
    final timeStr =
        '${modified.hour.toString().padLeft(2, '0')}:${modified.minute.toString().padLeft(2, '0')}';

    if (modifiedDay == today) {
      return '${t.home.today} $timeStr';
    } else if (modifiedDay == today.subtract(const Duration(days: 1))) {
      return '${t.home.yesterday} $timeStr';
    } else {
      return '${modified.year}/${modified.month.toString().padLeft(2, '0')}/${modified.day.toString().padLeft(2, '0')} $timeStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 缩略图
    final thumbnailWidget = SizedBox(
      height: thumbnailHeight,
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
                  '${filePath}${Editor.extension}.p',
                );
                if (imageFile.existsSync()) {
                  return Image(
                    image: FileImage(imageFile),
                    alignment: Alignment.topCenter,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const _FallbackThumbnail();
                    },
                  );
                }
                return const _FallbackThumbnail();
              },
            ),
          ],
        ),
      ),
    );

    // 标题
    final titleWidget = SizedBox(
      height: PreviewCard.titleHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            filePath.substring(filePath.lastIndexOf('/') + 1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );

    // 日期
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

    // 卡片：与主页 PreviewCard 的 OpenContainer 视觉一致
    return Material(
      color: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFE8EAED)
          : const Color(0xFF111115),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.light
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
    );
  }
}

class _FallbackThumbnail extends StatelessWidget {
  const _FallbackThumbnail();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: InnerCanvas.defaultBackgroundColor,
      child: Center(
        child: Text(
          t.home.noPreviewAvailable,
          style: TextTheme.of(context).bodyMedium?.copyWith(
                color: Colors.grey.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
