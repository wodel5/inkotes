part of 'editor_image.dart';

class PdfEditorImage extends EditorImage {
  Uint8List? pdfBytes;

  /// The index of the relevant page in the [_pdfDocument].
  /// The first page is 0.
  final int pdfPage;

  /// If the pdf needs to be loaded from disk, this is the File
  /// that the pdf will be loaded from.
  final File? pdfFile;

  final _pdfDocument = ValueNotifier<PdfDocument?>(null);

  static final log = Logger('PdfEditorImage');

  PdfEditorImage({
    required super.id,
    required super.assetCache,
    required this.pdfBytes,
    required this.pdfFile,
    required this.pdfPage,
    required super.pageIndex,
    required super.pageSize,
    super.backgroundFit,
    required super.onMoveImage,
    required super.onDeleteImage,
    required super.onMiscChange,
    super.onLoad,
    super.newImage,
    super.dstRect,
    required super.naturalSize,
    super.isThumbnail,
  }) : assert(
         !naturalSize.isEmpty,
         'naturalSize must be set for PdfEditorImage',
       ),
       assert(
         pdfBytes != null || pdfFile != null,
         'pdfFile must be set if pdfBytes is null',
       ),
       super(extension: '.pdf', srcRect: .zero);

  factory PdfEditorImage.fromJson(
    Map<String, dynamic> json, {
    bool isThumbnail = false,
    required String notePath,
    required AssetCache assetCache,
  }) {
    final extension = json['ext'] as String?;
    assert(extension == null || extension == '.pdf');

    final assetIndex = json['as'] as int?;
    final Uint8List? pdfBytes;
    File? pdfFile;
    if (assetIndex != null) {
      pdfFile = FileManager.getFile(
        '$notePath${Editor.extension}.$assetIndex',
      );
      pdfBytes = assetCache.get(pdfFile);
    } else {
      if (kDebugMode) {
        throw Exception('PdfEditorImage.fromJson: pdf bytes not found');
      }
      pdfBytes = Uint8List(0);
    }

    return PdfEditorImage(
      id:
          json['pid'] ??
          -1, // -1 will be replaced by EditorCoreInfo._handleEmptyImageIds()
      assetCache: assetCache,
      pdfBytes: pdfBytes,
      pdfFile: pdfFile,
      pdfPage: json['pdfp'],
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
      naturalSize: Size(json['natw'] ?? 0, json['nath'] ?? 0),
      isThumbnail: isThumbnail,
    );
  }

  @override
  Map<String, dynamic> toJson(OrderedAssetCache assets) {
    final json = super.toJson(assets);

    // remove non-pdf fields
    json.remove('th'); // thumbnail bytes
    assert(!json.containsKey('as'));
    assert(!json.containsKey('by'));

    json['as'] = assets.add(pdfFile ?? pdfBytes!);
    json['pdfp'] = pdfPage;

    return json;
  }

  @override
  Future<void> firstLoad() async {
    assert(srcRect.isEmpty);
    assert(!naturalSize.isEmpty);

    if (dstRect.isEmpty) {
      final dstSize = pageSize != null
          ? EditorImage.resize(naturalSize, pageSize!)
          : naturalSize;
      dstRect = dstRect.topLeft & dstSize;
    }

    assert(id != -1, 'id must be set before firstLoad is called');
    _pdfDocument.value ??= await assetCache.pdfDocumentCache.load(
      pdfFile?.path ?? 'inline_pdf_$id.pdf',
      pdfBytes: pdfBytes,
    );
    await _pdfDocument.value!.pages[pdfPage].ensureLoaded();
  }

  @override
  Future<void> loadIn() async => await super.loadIn();

  @override
  Future<bool> loadOut() async => await super.loadOut();

  @override
  Future<void> precache(BuildContext context) async {
    if (_pdfDocument.value != null) return;

    final completer = Completer<void>();

    void onDocumentSet() {
      if (_pdfDocument.value == null) return;
      if (completer.isCompleted) return;
      completer.complete();
      _pdfDocument.removeListener(onDocumentSet);
    }

    _pdfDocument.addListener(onDocumentSet);
    return completer.future;
  }

  @override
  Widget buildImageWidget({
    required BuildContext context,
    required BoxFit? overrideBoxFit,
    required bool isBackground,
  }) {
    return ValueListenableBuilder(
      valueListenable: _pdfDocument,
      builder: (context, pdfDocument, child) {
        if (pdfDocument == null) {
          return SizedBox.fromSize(size: srcRect.size);
        }
        return PdfPageView(
          document: pdfDocument,
          // [PdfPageView.pageNumber] starts at 1 not 0
          pageNumber: pdfPage + 1,
          decoration: const BoxDecoration(),
        );
      },
    );
  }

  @override
  PdfEditorImage copy() => PdfEditorImage(
    id: id,
    assetCache: assetCache,
    pdfBytes: pdfBytes,
    pdfPage: pdfPage,
    pdfFile: pdfFile,
    pageIndex: pageIndex,
    pageSize: .infinite,
    backgroundFit: backgroundFit,
    onMoveImage: onMoveImage,
    onDeleteImage: onDeleteImage,
    onMiscChange: onMiscChange,
    onLoad: onLoad,
    newImage: true,
    dstRect: dstRect,
    naturalSize: naturalSize,
    isThumbnail: isThumbnail,
  );

  @override
  void dispose() {
    pdfBytes = null;
    _pdfDocument.dispose();
    super.dispose();
  }
}
