part of 'editor_image.dart';

class PngEditorImage extends EditorImage {
  ImageProvider? imageProvider;

  Uint8List? thumbnailBytes;
  Size thumbnailSize = .zero;

  /// The maximum image size allowed for this image.
  /// If null, Prefs.maxImageSize will be used instead.
  Size? maxSize;

  @override
  set isThumbnail(bool isThumbnail) {
    super.isThumbnail = isThumbnail;
    if (isThumbnail && thumbnailBytes != null) {
      imageProvider = MemoryImage(thumbnailBytes!);
      final scale = thumbnailSize.width / naturalSize.width;
      srcRect = .fromLTWH(
        srcRect.left * scale,
        srcRect.top * scale,
        srcRect.width * scale,
        srcRect.height * scale,
      );
    }
  }

  PngEditorImage({
    required super.id,
    required super.assetCache,
    required super.extension,
    required this.imageProvider,
    required super.pageIndex,
    required super.pageSize,
    this.maxSize,
    super.backgroundFit,
    required super.onMoveImage,
    required super.onDeleteImage,
    required super.onMiscChange,
    super.onLoad,
    super.newImage,
    super.dstRect,
    super.srcRect,
    super.naturalSize,
    this.thumbnailBytes,
    super.isThumbnail,
    super.initialY,
  });

  factory PngEditorImage.fromJson(
    Map<String, dynamic> json, {
    bool isThumbnail = false,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    final assetIndex = json['as'] as int?;
    final Uint8List? bytes;
    File? imageFile;
    if (assetIndex != null) {
      imageFile = FileManager.getFile(
        '$sbnPath${Editor.extension}.$assetIndex',
      );
      bytes = assetCache.get(imageFile);
    } else if (json['by'] != null) {
      bytes = Uint8List.fromList((json['by'] as List<dynamic>).cast<int>());
    } else {
      if (kDebugMode) {
        throw Exception('EditorImage.fromJson: image bytes not found');
      }
      bytes = Uint8List(0);
    }
    assert(
      bytes != null || imageFile != null,
      'Either bytes or imageFile must be non-null',
    );

    return PngEditorImage(
      // -1 will be replaced by [EditorCoreInfo._handleEmptyImageIds()]
      id: json['pid'] ?? -1,
      assetCache: assetCache,
      extension: json['ext'] ?? '.jpg',
      imageProvider: bytes != null
          ? MemoryImage(bytes) as ImageProvider
          : FileImage(imageFile!),
      pageIndex: json['pg'] ?? 0,
      pageSize: .infinite,
      backgroundFit: json['fit'] != null ? .values[json['fit']] : .contain,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
      onLoad: null,
      newImage: false,
      dstRect: .fromLTWH(
        json['l'] ?? 0,
        json['t'] ?? 0,
        json['wd'] ?? 0,
        json['ht'] ?? 0,
      ),
      srcRect: .fromLTWH(
        json['sl'] ?? 0,
        json['st'] ?? 0,
        json['sw'] ?? 0,
        json['sh'] ?? 0,
      ),
      naturalSize: Size(json['natw'] ?? 0, json['nath'] ?? 0),
      thumbnailBytes: json['th'] != null
          ? Uint8List.fromList((json['th'] as List<dynamic>).cast<int>())
          : null,
      isThumbnail: isThumbnail,
    );
  }

  @override
  Map<String, dynamic> toJson(OrderedAssetCache assets) =>
      super.toJson(assets)
        ..addAll({if (imageProvider != null) 'as': assets.add(imageProvider!)});

  @override
  Future<void> firstLoad() async {
    assert(Isolate.current.debugName == 'main');

    if (srcRect.shortestSide == 0 || dstRect.shortestSide == 0) {
      final Uint8List bytes;
      if (imageProvider is MemoryImage) {
        bytes = (imageProvider as MemoryImage).bytes;
      } else if (imageProvider is FileImage) {
        bytes = await (imageProvider as FileImage).file.readAsBytes();
      } else {
        throw Exception(
          'EditorImage.getImage: imageProvider is ${imageProvider.runtimeType}',
        );
      }

      naturalSize = await ui.ImmutableBuffer.fromUint8List(bytes)
          .then((buffer) => ui.ImageDescriptor.encoded(buffer))
          .then(
            (descriptor) =>
                Size(descriptor.width.toDouble(), descriptor.height.toDouble()),
          );

      if (maxSize == null) {
        await stows.maxImageSize.waitUntilRead();
        maxSize = .square(stows.maxImageSize.value);
      }
      final Size reducedSize = EditorImage.resize(naturalSize, maxSize!);
      if (naturalSize.width != reducedSize.width && !isThumbnail) {
        await null; // wait for next event-loop iteration

        final resizedByteData = await resizeImage(
          bytes,
          width: reducedSize.width.toInt(),
          height: reducedSize.height.toInt(),
        );
        if (resizedByteData != null) {
          imageProvider = MemoryImage(resizedByteData.buffer.asUint8List());
        }

        naturalSize = reducedSize;
      }

      if (srcRect.shortestSide == 0) {
        srcRect = srcRect.topLeft & naturalSize;
      }
      if (dstRect.shortestSide == 0) {
        final Size dstSize = pageSize != null
            ? EditorImage.resize(naturalSize, pageSize! * 0.8)
            : naturalSize;
        final double x = pageSize != null
            ? (pageSize!.width - dstSize.width) / 2
            : 0.0;
        final double y = initialY ?? 0.0;
        var left = x;
        var top = y;
        if (pageSize != null) {
          const pad = 25.0;
          left = left.clamp(pad, max(pad, pageSize!.width - dstSize.width - pad));
          top = top.clamp(pad, max(pad, pageSize!.height - dstSize.height - pad));
        }
        dstRect = Rect.fromLTWH(left, top, dstSize.width, dstSize.height);
      }
    }

    if (naturalSize.shortestSide == 0) {
      naturalSize = Size(srcRect.width, srcRect.height);
    }

    if (isThumbnail) {
      isThumbnail = true; // updates bytes and srcRect
    }
  }

  @override
  Future<void> loadIn() async => await super.loadIn();
  @override
  Future<bool> loadOut() async => await super.loadOut();

  @override
  Future<void> precache(BuildContext context) async {
    if (imageProvider == null) return;
    return await precacheImage(imageProvider!, context);
  }

  @override
  Widget buildImageWidget({
    required BuildContext context,
    required BoxFit? overrideBoxFit,
    required bool isBackground,
  }) {
    final BoxFit boxFit;
    if (overrideBoxFit != null) {
      boxFit = overrideBoxFit;
    } else if (isBackground) {
      boxFit = backgroundFit;
    } else {
      boxFit = .fill;
    }

    return Image(image: imageProvider!, fit: boxFit);
  }

  @override
  PngEditorImage copy() => PngEditorImage(
    id: id,
    assetCache: assetCache,
    extension: extension,
    imageProvider: imageProvider,
    pageIndex: pageIndex,
    pageSize: .infinite,
    backgroundFit: backgroundFit,
    onMoveImage: onMoveImage,
    onDeleteImage: onDeleteImage,
    onMiscChange: onMiscChange,
    onLoad: onLoad,
    newImage: true,
    dstRect: dstRect,
    srcRect: srcRect,
    naturalSize: naturalSize,
    thumbnailBytes: thumbnailBytes,
    isThumbnail: isThumbnail,
  );
}
