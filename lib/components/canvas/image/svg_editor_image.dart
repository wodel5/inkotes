part of 'editor_image.dart';

class SvgEditorImage extends EditorImage {
  late SvgLoader svgLoader;

  static final log = Logger('SvgEditorImage');

  @override
  @Deprecated('Use the file directly instead')
  AssetCache get assetCache => super.assetCache;

  SvgEditorImage({
    required super.id,
    required super.assetCache,
    required String? svgString,
    required File? svgFile,
    required super.pageIndex,
    required super.pageSize,
    super.backgroundFit,
    required super.onMoveImage,
    required super.onDeleteImage,
    required super.onMiscChange,
    super.onLoad,
    super.newImage,
    super.dstRect,
    super.srcRect,
    super.naturalSize,
    super.isThumbnail,
    super.initialY,
  }) : assert(
         svgString != null || svgFile != null,
         'svgFile must be set if svgString is null',
       ),
       super(extension: '.svg') {
    if (svgString != null) {
      svgLoader = SvgStringLoader(svgString);
    } else {
      svgLoader = SvgFileLoader(svgFile!);
    }
  }

  factory SvgEditorImage.fromJson(
    Map<String, dynamic> json, {
    bool isThumbnail = false,
    required String notePath,
    required AssetCache assetCache,
  }) {
    final extension = json['ext'] as String?;
    assert(extension == null || extension == '.svg');

    final assetIndex = json['as'] as int?;
    final String? svgString;
    File? svgFile;
    if (assetIndex != null) {
      svgFile = FileManager.getFile(
        '$notePath${Editor.extension}.$assetIndex',
      );
      svgString = assetCache.get(svgFile);
    } else if (json['by'] != null) {
      svgString = json['by'] as String;
    } else {
      log.warning('SvgEditorImage.fromJson: no svg string found');
      svgString = '';
    }

    return SvgEditorImage(
      id:
          json['pid'] ??
          -1, // -1 will be replaced by EditorCoreInfo._handleEmptyImageIds()
      assetCache: assetCache,
      svgString: svgString,
      svgFile: svgFile,
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
      isThumbnail: isThumbnail,
    );
  }

  @override
  Map<String, dynamic> toJson(OrderedAssetCache assets) {
    final json = super.toJson(assets);

    // remove non-svg fields
    json.remove('th'); // thumbnail bytes
    assert(!json.containsKey('as'));
    assert(!json.containsKey('by'));

    final svgData = _extractSvg();
    json['as'] = assets.add(svgData.string ?? svgData.file!);

    return json;
  }

  ({String? string, File? file}) _extractSvg() => switch (svgLoader) {
    (final SvgStringLoader loader) => (
      string: loader.provideSvg(null),
      file: null,
    ),
    (final SvgFileLoader loader) => (string: null, file: loader.file),
    (_) => throw ArgumentError.value(
      svgLoader,
      'svgLoader',
      'SvgEditorImage.toJson: svgLoader must be a SvgStringLoader or SvgFileLoader',
    ),
  };

  @override
  Future<void> firstLoad() async {
    if (srcRect.shortestSide == 0 || dstRect.shortestSide == 0) {
      final pictureInfo = await vg.loadPicture(svgLoader, null);
      naturalSize = pictureInfo.size;
      pictureInfo.picture.dispose();

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

    if (naturalSize == .zero) {
      naturalSize = Size(srcRect.width, srcRect.height);
    }
  }

  @override
  Future<void> loadIn() async => await super.loadIn();

  @override
  Future<bool> loadOut() async => await super.loadOut();

  @override
  Future<void> precache(BuildContext context) async {
    final pictureInfo = await vg.loadPicture(svgLoader, null);
    pictureInfo.picture.dispose();
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

    return SvgPicture(svgLoader, fit: boxFit);
  }

  @override
  SvgEditorImage copy() {
    final svgData = _extractSvg();
    return SvgEditorImage(
      id: id,
      // ignore: deprecated_member_use_from_same_package
      assetCache: assetCache,
      svgString: svgData.string,
      svgFile: svgData.file,
      pageIndex: pageIndex,
      pageSize: .infinite,
      backgroundFit: backgroundFit,
      onMoveImage: onMoveImage,
      onDeleteImage: onDeleteImage,
      onMiscChange: onMiscChange,
      onLoad: onLoad,
      newImage: newImage,
      dstRect: dstRect,
      srcRect: srcRect,
      naturalSize: naturalSize,
      isThumbnail: isThumbnail,
    );
  }
}
