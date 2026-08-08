import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 应用更新信息。
class UpdateInfo {
  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.fileName,
    this.body,
  });

  final String latestVersion;
  final String downloadUrl;
  final String fileName;
  final String? body;
}

/// 更新检查与下载服务。
///
/// 当前为**模拟实现**：`checkForUpdates` 总是返回一个高于当前版本的新版本，
/// `download` 用定时器模拟下载进度。后续接入真实 API
/// （GitHub/Gitee Releases）时只需替换这两个方法。
class UpdateService {
  UpdateService._();

  /// 是否有可下载的新版本。
  static final hasNewVersion = ValueNotifier<bool>(false);

  /// 下载进度 0.0~1.0，null 表示尚未开始下载。
  static final downloadProgress = ValueNotifier<double?>(null);

  /// 最新更新信息。
  static UpdateInfo? latestUpdate;

  static Timer? _downloadTimer;

  /// 检查更新。当前模拟：总是发现新版本 `0.2.0`。
  ///
  /// TODO: 根据 [source] 请求真实 Releases API，解析最新版本与下载地址。
  static Future<UpdateInfo?> checkForUpdates({UpdateSource? source}) async {
    final currentVersion = await _getCurrentVersion();

    // 模拟新版本
    const mockLatest = '0.2.0';
    final info = UpdateInfo(
      latestVersion: mockLatest,
      downloadUrl: 'https://example.com/inkotes-$mockLatest.apk',
      fileName: 'inkotes-$mockLatest.apk',
      body: '''
- 新增应用内更新功能，支持检查更新源切换（GitHub/Gitee）
- 主页设置按钮新增更新提示红点
- 新增下载更新与进度显示
- 修复笔记卡片缩略图显示问题
- 优化编辑器文件名重命名交互''',
    );

    latestUpdate = info;
    hasNewVersion.value = compareVersion(mockLatest, currentVersion) > 0;
    return hasNewVersion.value ? info : null;
  }

  /// 当前应用版本号（如 `0.1.0-beta1`）。
  static Future<String> _getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 比较两个版本号，返回正数表示 [a] 更新。
  static int compareVersion(String a, String b) {
    final aParts = _parseVersion(a);
    final bParts = _parseVersion(b);
    final length = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (int i = 0; i < length; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av != bv) return av - bv;
    }
    return 0;
  }

  /// 提取版本号中的数字段（如 `0.1.0-beta1` -> `[0, 1, 0]`）。
  static List<int> _parseVersion(String version) {
    final match = RegExp(r'\d+(\.\d+)*').firstMatch(version);
    if (match == null) return const [];
    return match.group(0)!.split('.').map(int.parse).toList();
  }

  /// 开始下载。当前模拟：定时器递增进度到 100%。
  ///
  /// TODO: 使用真实下载（如 dio）替换，通过进度回调更新 [downloadProgress]。
  static void download() {
    if (_downloadTimer?.isActive ?? false) return;
    downloadProgress.value = 0;
    var progress = 0.0;
    _downloadTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      progress += 0.02;
      if (progress >= 1) {
        progress = 1;
        timer.cancel();
      }
      downloadProgress.value = progress;
    });
  }

  /// 停止下载（模拟：取消定时器）。
  static void cancelDownload() {
    _downloadTimer?.cancel();
    _downloadTimer = null;
  }
}
