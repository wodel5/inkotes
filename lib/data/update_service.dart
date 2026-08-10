import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('UpdateService');

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
/// 根据 [stows.updateSource]（GitHub/Gitee）请求对应 Releases API，
/// 比较最新版本与当前版本，并提供 APK 下载（进度通过 [downloadProgress] 暴露）。
class UpdateService {
  UpdateService._();

  static const _githubOwner = 'wodel5';
  static const _githubRepo = 'inkotes';
  static const _giteeOwner = 'wodel-five';
  static const _giteeRepo = 'inkotes';

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  /// 是否有可下载的新版本。
  static final hasNewVersion = ValueNotifier<bool>(false);

  /// 下载进度 0.0~1.0，null 表示尚未开始下载。
  static final downloadProgress = ValueNotifier<double?>(null);

  /// 最新更新信息。
  static UpdateInfo? latestUpdate;

  static CancelToken? _downloadToken;

  static String _apiUrl(UpdateSource source) {
    switch (source) {
      case UpdateSource.github:
        return 'https://api.github.com/repos/$_githubOwner/$_githubRepo/releases/latest';
      case UpdateSource.gitee:
        return 'https://gitee.com/api/v5/repos/$_giteeOwner/$_giteeRepo/releases/latest';
    }
  }

  /// 检查更新。成功且发现新版本时设置 [hasNewVersion] 并返回信息，
  /// 否则返回 null（网络失败等异常被静默吞掉）。
  static Future<UpdateInfo?> checkForUpdates({UpdateSource? source}) async {
    final src = source ?? stows.updateSource.value;
    try {
      final response = await _dio.get(_apiUrl(src));
      final data = response.data;
      if (data is! Map<String, dynamic>) return null;

      final tagName = (data['tag_name'] as String?) ?? '';
      final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final body = (data['body'] as String?) ?? '';
      final assets = (data['assets'] as List<dynamic>?) ?? const [];

      String? downloadUrl;
      String? fileName;
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = (asset['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          fileName = name;
          downloadUrl = (asset['browser_download_url'] as String?) ?? '';
          if (downloadUrl.isEmpty) {
            // Gitee 的 asset 使用 download_url 字段
            downloadUrl = (asset['download_url'] as String?) ?? '';
          }
          if (downloadUrl.isNotEmpty) break;
        }
      }
      if (downloadUrl == null || downloadUrl.isEmpty) return null;

      final info = UpdateInfo(
        latestVersion: version,
        downloadUrl: downloadUrl,
        fileName: fileName ?? 'inkotes.apk',
        body: body,
      );
      latestUpdate = info;
      hasNewVersion.value = compareVersion(version, await getCurrentVersion()) > 0;
      return hasNewVersion.value ? info : null;
    } catch (e) {
      _log.warning('Failed to check for updates: $e');
      hasNewVersion.value = false;
      return null;
    }
  }

  /// 当前应用版本号（如 `0.1.0-beta1`）。
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 按 SemVer 规则比较两个版本号，返回正数表示 [a] 更新。
  ///
  /// 规则：先比较 `主.次.补丁` 数字段；数字相同再看预发布后缀
  /// （`-alpha`/`-beta`/`-rc`），正式版（无后缀）大于预发布。
  /// 例：`0.1.0-beta1 < 0.1.0-beta2 < 0.1.0 < 0.2.0`。
  static int compareVersion(String a, String b) {
    final aCore = _parseCore(a);
    final bCore = _parseCore(b);
    final length = aCore.length > bCore.length ? aCore.length : bCore.length;
    for (int i = 0; i < length; i++) {
      final av = i < aCore.length ? aCore[i] : 0;
      final bv = i < bCore.length ? bCore[i] : 0;
      if (av != bv) return av - bv;
    }
    return _comparePrerelease(_parsePrerelease(a), _parsePrerelease(b));
  }

  /// 提取版本号的主版本数字段（如 `0.1.0-beta1` -> `[0, 1, 0]`）。
  static List<int> _parseCore(String version) {
    final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(version);
    if (match == null) return const [];
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }

  /// 提取预发布后缀（`-` 后面的部分），按 `.` 分段；无后缀返回 null。
  static List<String>? _parsePrerelease(String version) {
    final idx = version.indexOf('-');
    if (idx == -1) return null;
    final pre = version.substring(idx + 1);
    return pre.isEmpty ? null : pre.split('.');
  }

  /// 比较预发布后缀：null（正式版）大于任何预发布。
  /// 数字段按数值比较，非数字段按字典序，数字段小于非数字段。
  static int _comparePrerelease(List<String>? a, List<String>? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;

    final length = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < length; i++) {
      if (i >= a.length) return -1; // a 更短 -> a 更小
      if (i >= b.length) return 1;

      final ai = int.tryParse(a[i]);
      final bi = int.tryParse(b[i]);
      if (ai != null && bi != null) {
        if (ai != bi) return ai - bi;
      } else if (ai != null) {
        return -1; // 数字标识符 < 字母标识符
      } else if (bi != null) {
        return 1;
      } else {
        final cmp = a[i].compareTo(b[i]);
        if (cmp != 0) return cmp;
      }
    }
    return 0;
  }

  /// 下载最新版 APK 到应用临时目录，进度通过 [downloadProgress] 暴露。
  /// 返回下载完成的文件路径；失败返回 null。
  static Future<String?> download() async {
    final info = latestUpdate;
    if (info == null) return null;

    _cancelled = false;
    _downloadToken?.cancel();
    _downloadToken = CancelToken();
    downloadProgress.value = 0;

    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${info.fileName}';
      await _dio.download(
        info.downloadUrl,
        filePath,
        cancelToken: _downloadToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            downloadProgress.value = (received / total).clamp(0.0, 1.0);
          }
        },
      );
      if (!await File(filePath).exists()) return null;
      downloadProgress.value = 1.0;
      return filePath;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // 用户主动取消：清空进度，不视为失败
        _cancelled = true;
        downloadProgress.value = null;
        return null;
      }
      _log.warning('Failed to download update: $e');
      downloadProgress.value = null;
      return null;
    } catch (e) {
      _log.warning('Failed to download update: $e');
      downloadProgress.value = null;
      return null;
    }
  }

  /// 最近一次 [download] 是否被用户取消。
  static bool get wasCancelled => _cancelled;
  static bool _cancelled = false;

  /// 取消正在进行的下载。
  static void cancelDownload() {
    _downloadToken?.cancel();
    _downloadToken = null;
    _mockTimer?.cancel();
    _mockTimer = null;
    downloadProgress.value = null;
  }

  static Timer? _mockTimer;

  /// 模拟下载（仅测试用）：不请求网络、不下载文件，
  /// 直接让下载进度从 0 平滑增长到 100%，用于预览下载 UI。
  static void mockDownload() {
    _downloadToken?.cancel();
    _downloadToken = null;
    _mockTimer?.cancel();
    downloadProgress.value = 0;
    _mockTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      final current = downloadProgress.value ?? 0;
      final next = current + 0.01;
      if (next >= 1) {
        downloadProgress.value = 1.0;
        timer.cancel();
        _mockTimer = null;
      } else {
        downloadProgress.value = next;
      }
    });
  }

  static const MethodChannel _installChannel = MethodChannel('update/install');

  /// 调用系统安装界面安装下载好的 APK（通过原生 FileProvider）。
  static Future<void> installApk(String filePath) async {
    await _installChannel.invokeMethod('install', {'path': filePath});
  }
}
