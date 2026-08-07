import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

/// Handles exporting files to the device (save to gallery, share, etc.).
class FileExporter {
  FileExporter._();

  static final log = Logger('FileExporter');

  static Future exportFile(
    String fileName,
    List<int> bytes, {
    bool isImage = false,
    required BuildContext context,
  }) async {
    File? tempFile;
    Future<File> getTempFile() async {
      final tempFolder = (await getTemporaryDirectory()).path;
      final file = File('$tempFolder/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      if (isImage) {
        final permissionGranted = await _requestPhotosPermission();
        if (permissionGranted) {
          await SaverGallery.saveImage(
            Uint8List.fromList(bytes),
            fileName: fileName,
            albumPath: 'inkotes',
            skipIfExists: true,
          );
        }
      } else {
        if (Platform.isIOS) {
          tempFile = await getTempFile();
          if (!context.mounted) return;
          final box = context.findRenderObject() as RenderBox;
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(tempFile.path)],
              sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
            ),
          );
        } else {
          // Android: save the file via the system save dialog (SAF),
          // since the share sheet won't list the sharing app itself.
          final outputFile = await FilePicker.saveFile(
            fileName: fileName,
            bytes: Uint8List.fromList(bytes),
            type: FileType.custom,
            allowedExtensions: [fileName.split('.').last],
          );
          if (outputFile != null) {
            log.info('Saved file to $outputFile');
          }
        }
      }
    } else {
      final outputFile = await FilePicker.saveFile(
        fileName: fileName,
        initialDirectory: (await getDownloadsDirectory())?.path,
        type: FileType.custom,
        allowedExtensions: [fileName.split('.').last],
      );
      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    }

    await tempFile?.delete();
  }

  static Future<bool> _requestPhotosPermission() async {
    if (Platform.isIOS) {
      return await Permission.photosAddOnly.request().isGranted;
    } else if (!Platform.isAndroid) {
      return true;
    }

    final sdkInt = await DeviceInfoPlugin().androidInfo.then(
      (info) => info.version.sdkInt,
    );
    if (sdkInt > 33) {
      return await Permission.photos.request().isGranted;
    } else {
      return await Permission.storage.request().isGranted;
    }
  }
}
