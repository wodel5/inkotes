import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/theming/uni_icon.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/update_service.dart';
import 'package:inkotes/i18n/strings.g.dart';

/// 检查更新源设置项：图标 + 标题 + 更新来源切换（GitHub/Gitee）。
///
/// 应用始终自动检查更新。有新版本时，标题右侧出现"下载更新"按钮；
/// 下载中图标变为圆形进度条，并弹出下载进度弹窗（点击空白处可关闭）。
class UpdateCheckSettings extends StatefulWidget {
  const UpdateCheckSettings({super.key});

  @override
  State<UpdateCheckSettings> createState() => _UpdateCheckSettingsState();
}

class _UpdateCheckSettingsState extends State<UpdateCheckSettings> {
  @override
  void initState() {
    stows.updateSource.addListener(onChanged);
    // 语言切换时刷新文案，与其他设置项保持一致
    stows.locale.addListener(onChanged);
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: ValueListenableBuilder<double?>(
        valueListenable: UpdateService.downloadProgress,
        builder: (context, progress, _) {
          // 下载中：图标变为圆形进度条
          if (progress != null) {
            return SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(value: progress, strokeWidth: 3),
            );
          }
          return const UniIcon(FontAwesomeIcons.arrowsRotate, size: 26);
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              t.settings.checkUpdateSource,
              style: const TextStyle(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 有新版本时显示"下载更新"按钮
          ValueListenableBuilder<bool>(
            valueListenable: UpdateService.hasNewVersion,
            builder: (context, hasNewVersion, _) {
              if (!hasNewVersion) return const SizedBox.shrink();
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
        constraints: const BoxConstraints(minWidth: 90, minHeight: 40),
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
    );
  }

  @override
  void dispose() {
    stows.updateSource.removeListener(onChanged);
    stows.locale.removeListener(onChanged);
    super.dispose();
  }
}

/// 发现新版本弹窗：显示新版本号与更新日志，可点击空白处关闭。
/// 点击"下载更新"后，弹窗内出现下载进度条（下载在后台继续）。
Future<void> showUpdateDialog(BuildContext context) {
  final info = UpdateService.latestUpdate;
  if (info == null) return Future.value();

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      var downloading = false;
      var failed = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              t.settings.update.newVersion(version: info.latestVersion),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.settings.update.changelog,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(info.body ?? ''),
                  ),
                ),
                // 点击"下载更新"后出现进度条
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
            actions: [
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
                    if (context.mounted) setState(() => failed = true);
                  } else {
                    // 下载完成，跳转系统安装界面
                    await UpdateService.installApk(path);
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
