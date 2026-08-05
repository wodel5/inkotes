/// Constants for the Editor, extracted to avoid circular imports in mixins.
class EditorConstants {
  EditorConstants._();

  /// The file extension used by the app (BSON format).
  static const extension = '.fln';

  /// Gap between pages in the canvas.
  static const double gapBetweenPages = 16;

  /// Whether the platform can rasterize a PDF.
  static bool canRasterPdf = true;
}
