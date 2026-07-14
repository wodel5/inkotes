abstract class RoutePaths {
  static const home = '/';
  static const edit = '/edit';

  static String editFilePath(String filePath) {
    return '$edit?path=${Uri.encodeQueryComponent(filePath)}';
  }

  static String editImportPdf(String filePath, String pdfPath) {
    return '$edit'
        '?path=${Uri.encodeQueryComponent(filePath)}'
        '&pdfPath=${Uri.encodeQueryComponent(pdfPath)}';
  }
}
