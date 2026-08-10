import 'dart:ui' show GradientTransform;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/theming/uni_icon.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/update_service.dart';
import 'package:inkotes/i18n/strings.g.dart';

/// 检查更新源设置项：图标 + 标题 + 更新来源切换（GitHub/Gitee）。
///
/// 应用始终自动检查更新。有新版本且未在下载时，标题右侧出现"下载更新"按钮；
/// 下载中（含后台下载）图标变为圆形进度条，此时点击整行可呼出下载进度弹窗。
class UpdateCheckSettings extends StatefulWidget {
  const UpdateCheckSettings({super.key});

  @override
  State<UpdateCheckSettings> createState() => _UpdateCheckSettingsState();
}

class _UpdateCheckSettingsState extends State<UpdateCheckSettings>
    with TickerProviderStateMixin {
  // 下载中让"检查更新"图标持续旋转
  late final AnimationController _rotationController;

  // 水灌效果：填充区域高光带从左往右循环流动
  late final AnimationController _waveController;

  @override
  void initState() {
    stows.updateSource.addListener(onChanged);
    // 语言切换时刷新文案，与其他设置项保持一致
    stows.locale.addListener(onChanged);
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  void _onDownloadPressed() {
    showUpdateDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final source = stows.updateSource.value;

    return ValueListenableBuilder<double?>(
      valueListenable: UpdateService.downloadProgress,
      builder: (context, progress, _) {
        final isDownloading = progress != null;
        // 下载中：图标持续旋转 + 水灌动画；停止时复位
        if (isDownloading) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
          if (!_waveController.isAnimating) {
            _waveController.repeat();
          }
        } else {
          _rotationController.stop();
          _rotationController.value = 0;
          _waveController.stop();
          _waveController.value = 0;
        }
        final fill = progress == null ? 0.0 : progress.clamp(0.0, 1.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // 底层：下载进度从左到右填充主题色（整条设置项）
              Positioned.fill(
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fill,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, _) {
                      // 高光带位置随动画从左往右循环（固定宽度渐变平移）
                      final t = _waveController.value;
                      final primary = Theme.of(
                        context,
                      ).colorScheme.primary;
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primary.withValues(alpha: 0.10),
                              primary.withValues(alpha: 0.30),
                              primary.withValues(alpha: 0.10),
                            ],
                            stops: const [0.0, 0.18, 0.36],
                            transform: _GradientTranslation(t),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              ListTile(
                // 下载中：点击整行呼出下载进度弹窗
                onTap: isDownloading ? _onDownloadPressed : null,
                // 长按触发模拟下载（测试用，不调更新 API）
                onLongPress: isDownloading
                    ? null
                    : () => UpdateService.mockDownload(),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 16,
                ),
                leading: RotationTransition(
                  turns: _rotationController,
                  child: const UniIcon(
                    FontAwesomeIcons.arrowsRotate,
                    size: 24,
                  ),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        isDownloading
                            ? t.settings.update.downloadingTitle
                            : t.settings.checkUpdateSource,
                        style: const TextStyle(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // 有新版本且未在下载时显示"下载更新"按钮
                    ValueListenableBuilder<bool>(
                      valueListenable: UpdateService.hasNewVersion,
                      builder: (context, hasNewVersion, _) {
                        if (!hasNewVersion || isDownloading) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: _onDownloadPressed,
                            child: Text(t.settings.update.downloadUpdate),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                trailing: ToggleButtons(
                  borderRadius: const BorderRadius.all(Radius.circular(1000)),
                  // 2 个选项的宽度对齐上面 3 个选项的 SettingsSelection（60 x 3）
                  constraints: const BoxConstraints(
                    minWidth: 90,
                    minHeight: 40,
                  ),
                  onPressed: (int index) {
                    stows.updateSource.value = UpdateSource.values[index];
                    // 切换来源后重新检查更新，红点状态随之刷新
                    UpdateService.checkForUpdates(
                      source: stows.updateSource.value,
                    );
                  },
                  isSelected: [
                    for (final option in UpdateSource.values) option == source,
                  ],
                  children: const [
                    Text('GitHub'),
                    Text('Gitee'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    stows.updateSource.removeListener(onChanged);
    stows.locale.removeListener(onChanged);
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }
}

/// 水平平移渐变：把高光带按 [dx]（0~1，相对宽度比例）向右平移。
class _GradientTranslation implements GradientTransform {
  const _GradientTranslation(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * dx, 0, 0);
  }
}

/// 更新弹窗：
/// - 未下载时：发现新版本 + 更新日志 + 取消/下载更新
/// - 下载中（含后台下载恢复）：下载进度条 + 取消下载/后台下载
Future<void> showUpdateDialog(BuildContext context) {
  final info = UpdateService.latestUpdate;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      // 打开时是否已在下载（后台下载后重新呼出）
      var downloading = UpdateService.downloadProgress.value != null;
      var failed = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              t.settings.update.newVersion(version: info?.latestVersion ?? ''),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 更新日志始终显示（下载中也不例外）
                Text(
                  t.settings.update.changelog,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(info?.body ?? ''),
                  ),
                ),
                // 点击"下载更新"后在原窗口内出现横向进度条
                if (downloading) ...[
                  const SizedBox(height: 12),
                  ValueListenableBuilder<double?>(
                    valueListenable: UpdateService.downloadProgress,
                    builder: (context, progress, _) {
                      final percent = progress == null
                          ? 0
                          : (progress * 100).round().clamp(0, 100);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(value: progress ?? 0),
                          ),
                          const SizedBox(height: 8),
                          if (failed)
                            Text(
                              t.settings.update.downloadFailed,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            )
                          else
                            Text(
                              progress != null && progress >= 1
                                  ? t.settings.update.downloaded
                                  : t.settings.update.downloading(
                                      percent: '$percent%',
                                    ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
            actions: downloading
                ? [
                    // 取消下载：终止下载并关闭弹窗
                    TextButton(
                      onPressed: () {
                        UpdateService.cancelDownload();
                        Navigator.of(context).pop();
                      },
                      child: Text(t.settings.update.cancelDownload),
                    ),
                    // 后台下载：关闭弹窗，下载在后台继续
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.settings.update.backgroundDownload),
                    ),
                  ]
                : [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(t.common.cancel),
                    ),
                    FilledButton(
                      onPressed: () async {
                        setState(() {
                          downloading = true;
                          failed = false;
                        });
                        final path = await UpdateService.download();
                        if (path == null) {
                          // 用户主动取消不算失败，不显示"下载失败"
                          if (context.mounted && !UpdateService.wasCancelled) {
                            setState(() => failed = true);
                          }
                        } else {
                          // 下载完成，跳转系统安装界面
                          await UpdateService.installApk(path);
                          if (context.mounted) Navigator.of(context).pop();
                        }
                      },
                      child: Text(t.settings.update.downloadUpdate),
                    ),
                  ],
          );
        },
      );
    },
  );
}
