abstract class RoutePaths {
  static const home = '/';
  static const edit = '/edit';
  static const trash = '/trash';
  static const settings = '/settings';

  static String editFilePath(String filePath) {
    return '$edit?path=${Uri.encodeQueryComponent(filePath)}';
  }

  static String editImportPdf(String filePath, String pdfPath) {
    return '$edit'
        '?path=${Uri.encodeQueryComponent(filePath)}'
        '&pdfPath=${Uri.encodeQueryComponent(pdfPath)}';
  }
}
