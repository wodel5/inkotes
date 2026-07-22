import 'dart:async';

import 'package:collapsible/collapsible.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:foledge/components/home/delete_note_button.dart';
import 'package:foledge/components/home/export_note_button.dart';
import 'package:foledge/components/home/grid_folders.dart';
import 'package:foledge/components/home/masonry_files.dart';
import 'package:foledge/components/home/move_note_button.dart';
import 'package:foledge/components/home/rename_note_button.dart';
import 'package:foledge/data/file_manager/file_manager.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/data/routes.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:foledge/pages/editor/editor.dart';
import 'package:foledge/pages/home/settings.dart';

class HomePage extends StatefulHookWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final log = Logger('HomePage');

  /// Current browsing path. null means root.
  String? currentPath;

  /// All files (notes) at the current path level
  final List<String> filePaths = [];

  /// Directories (folders) at the current path level
  List<String> folders = [];

  var failed = false;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  // Search state
  var _isSearching = false;
  final _searchController = TextEditingController();
  List<String> _searchResults = [];
  List<String> _allFiles = [];

  @override
  void initState() {
    findChildren();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_setState);

    // Fix incorrectly imported files
    moveIncorrectlyImportedFiles();

    super.initState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
    fileWriteSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    findChildren(fromFileListener: true);
  }

  void _setState() => setState(() {});

  /// Mitigates a bug where files got imported starting with `null/` instead of `/`.
  void moveIncorrectlyImportedFiles() async {
    for (final filePath in stows.recentFiles.value) {
      if (filePath.startsWith('/')) continue;

      final String newFilePath;
      if (filePath.startsWith('null/')) {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          filePath.substring('null'.length),
        );
      } else {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          '/$filePath',
        );
      }

      log.warning(
        'Found incorrectly imported file at `$filePath`; moving to `$newFilePath`',
      );
      await FileManager.moveFile(filePath, newFilePath);
    }
  }

  Future findChildren({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      final location = GoRouterState.of(context).uri.toString();
      if (location != RoutePaths.home) return;
    }

    if (currentPath == null) {
      // Root level: show recent files + folders
      final recentFiles = await FileManager.getRecentlyAccessed();
      filePaths.clear();
      if (recentFiles.isEmpty) {
        failed = true;
      } else {
        failed = false;
        filePaths.addAll(recentFiles);
      }

      // Get folders at root
      final children = await FileManager.getChildrenOfDirectory(
        '/',
        sortMetric: stows.browseSortMetric.value,
      );
      folders = children?.directories ?? [];
    } else {
      // Browsing a specific folder
      final children = await FileManager.getChildrenOfDirectory(
        currentPath!,
        sortMetric: stows.browseSortMetric.value,
      );
      if (children == null) {
        failed = true;
        filePaths.clear();
        folders = [];
      } else {
        failed = false;
        filePaths.clear();
        filePaths.addAll([
          for (final filePath in children.files) "${currentPath!}/$filePath",
        ]);
        folders = children.directories;
      }
    }

    if (mounted) setState(() {});
  }

  void onDirectoryTap(String folder) {
    selectedFiles.value = [];
    if (folder == '..') {
      currentPath = p.dirname(currentPath ?? '/');
      if (currentPath == '/') currentPath = null;
    } else {
      currentPath = p.join(currentPath ?? '/', folder);
    }
    findChildren();
  }

  Future<void> createFolder(String folderName) async {
    final folderPath = '${currentPath ?? ''}/$folderName';
    await FileManager.createFolder(folderPath);
    findChildren();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchController.clear();
      _searchResults = [];
    });
    FileManager.getAllFiles().then((files) {
      _allFiles = files;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
      _allFiles = [];
    });
  }

  void _onSearchQueryChanged(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _allFiles
            .where((file) {
              final name = file.split('/').last.toLowerCase();
              return name.contains(q);
            })
            .toList();
      }
    });
  }

  void _showSettingsOverlay(BuildContext context, Rect buttonRect) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Settings',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SettingsOverlay(buttonRect: buttonRect);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  Future<void> _importPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || !mounted) return;

    final filePath = result.files.single.path;
    final fileName = result.files.single.name;
    if (filePath == null) return;

    if (!Editor.canRasterPdf) return;

    final fileNameWithoutExtension = fileName.substring(
      0,
      fileName.length - '.pdf'.length,
    );
    final sbnFilePath = await FileManager.suffixFilePathToMakeItUnique(
      '${currentPath ?? ''}/$fileNameWithoutExtension',
    );
    if (!mounted) return;
    context.push(RoutePaths.editImportPdf(sbnFilePath, filePath));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300 + 1;
    useOnListenableChange(stows.browseSortMetric, findChildren);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight,
        titleSpacing: 24,
        title: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // App title (fades out when searching)
            AnimatedOpacity(
              opacity: _isSearching ? 0 : 1,
              duration: const Duration(milliseconds: 300),
              child: Text(
                t.home.titles.appName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Search field (scales in from right when searching)
            AnimatedScale(
              scale: _isSearching ? 1 : 0,
              alignment: Alignment.centerRight,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _isSearching ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: TextField(
                  controller: _searchController,
                  autofocus: _isSearching,
                  decoration: InputDecoration(
                    hintText: t.home.searchNotes,
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onSearchQueryChanged,
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 24),
        actions: [
          SizedBox(
            width: 200,
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                // Normal buttons row
                IgnorePointer(
                  ignoring: _isSearching,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Add button (fades out when searching)
                      AnimatedOpacity(
                        opacity: _isSearching ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const FaIcon(FontAwesomeIcons.plus),
                            onPressed: () {
                              final RenderBox button =
                                  context.findRenderObject() as RenderBox;
                              final buttonRect = button.localToGlobal(Offset.zero) & button.size;
                              final position = RelativeRect.fromLTRB(
                                buttonRect.left - buttonRect.width,
                                buttonRect.top + buttonRect.height,
                                buttonRect.left - buttonRect.width,
                                buttonRect.top + buttonRect.height,
                              );
                              showMenu(
                                context: context,
                                position: position,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(kYaruContainerRadius),
                                ),
                                items: [
                                  PopupMenuItem(
                                    value: 'create',
                                    child: ListTile(
                                      leading: const FaIcon(FontAwesomeIcons.fileCirclePlus),
                                      title: Text(t.home.create.newNote, style: const TextStyle(fontSize: 16)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: ListTile(
                                      leading: const FaIcon(FontAwesomeIcons.solidFilePdf),
                                      title: Text(t.home.importPdf, style: const TextStyle(fontSize: 16)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ).then((value) async {
                                if (value == 'create') {
                                  final router = GoRouter.of(context);
                                  final path = currentPath;
                                  final newFilePath = await FileManager.newFilePath(
                                    '${path ?? ''}/',
                                  );
                                  if (!mounted) return;
                                  router.push(RoutePaths.editFilePath(newFilePath));
                                } else if (value == 'pdf') {
                                  _importPdf();
                                }
                              });
                            },
                          ),
                        ),
                      ),
                      // Search button (fades out when searching)
                      AnimatedOpacity(
                        opacity: _isSearching ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.magnifyingGlass),
                          onPressed: _startSearch,
                        ),
                      ),
                      // Trash button (fades out when searching)
                      AnimatedOpacity(
                        opacity: _isSearching ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.auto_delete_rounded),
                            onPressed: () {
                              // TODO: trash
                            },
                          ),
                        ),
                      ),
                      // Settings button (fades out when searching)
                      AnimatedOpacity(
                        opacity: _isSearching ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: Builder(
                          builder: (context) => IconButton(
                            icon: const FaIcon(FontAwesomeIcons.gear),
                            onPressed: () {
                              final RenderBox button =
                                  context.findRenderObject() as RenderBox;
                              final buttonRect = button.localToGlobal(Offset.zero) & button.size;
                              _showSettingsOverlay(context, buttonRect);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button (starts at search button position, slides right when searching)
                AnimatedSlide(
                  offset: _isSearching ? Offset.zero : const Offset(-3, 0),
                  duration: const Duration(milliseconds: 300),
                  child: AnimatedScale(
                    scale: _isSearching ? 1 : 0,
                    alignment: Alignment.centerLeft,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _isSearching ? 1 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_isSearching,
                        child: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.xmark, color: Colors.red),
                          onPressed: _stopSearch,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Folder path breadcrumb
          if (currentPath != null)
            _PathBreadcrumb(
              path: currentPath!,
              onTap: (path) {
                currentPath = path.isEmpty ? null : path;
                findChildren();
              },
            ),
          // Main content
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildBody(crossAxisCount),
          ),
        ],
      ),
      persistentFooterButtons: selectedFiles.value.isEmpty
          ? null
          : [
              Collapsible(
                axis: CollapsibleAxis.vertical,
                collapsed: selectedFiles.value.length != 1,
                child: RenameNoteButton(
                  existingPath: selectedFiles.value.isEmpty
                      ? ''
                      : selectedFiles.value.first,
                  unselectNotes: () => selectedFiles.value = [],
                ),
              ),
              MoveNoteButton(
                filesToMove: selectedFiles.value,
                unselectNotes: () => selectedFiles.value = [],
              ),
              DeleteNoteButton(
                filesToDelete: selectedFiles.value,
                unselectNotes: () => selectedFiles.value = [],
              ),
              ExportNoteButton(selectedFiles: selectedFiles.value),
            ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(t.home.searchNoResults),
      );
    }

    final colorScheme = ColorScheme.of(context);
    final crossAxisCount = MediaQuery.sizeOf(context).width ~/ 300 + 1;

    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 70),
          sliver: MasonryFiles(
            crossAxisCount: crossAxisCount,
            files: _searchResults,
            selectedFiles: selectedFiles,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(int crossAxisCount) {
    if (failed && currentPath == null) {
      return _buildWelcome();
    }

    return CustomScrollView(
      slivers: [
        // Back folder button (when inside a subfolder)
        if (currentPath != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_back),
                  title: Text(t.home.backFolder),
                  onTap: () => onDirectoryTap('..'),
                ),
              ),
            ),
          ),
        // Folders
        if (folders.isNotEmpty)
          GridFolders(
            isAtRoot: currentPath == null,
            crossAxisCount: crossAxisCount,
            onTap: onDirectoryTap,
            createFolder: createFolder,
            doesFolderExist: (String folderName) {
              return folders.contains(folderName);
            },
            renameFolder: (String oldName, String newName) async {
              final oldPath = '${currentPath ?? ''}/$oldName';
              await FileManager.renameDirectory(oldPath, newName);
              findChildren();
            },
            isFolderEmpty: (String folderName) async {
              final folderPath = '${currentPath ?? ''}/$folderName';
              final children = await FileManager.getChildrenOfDirectory(
                folderPath,
              );
              return children?.isEmpty ?? true;
            },
            deleteFolder: (String folderName) async {
              final folderPath = '${currentPath ?? ''}/$folderName';
              await FileManager.deleteDirectory(folderPath);
              findChildren();
            },
            folders: folders,
          ),
        // Notes
        if (filePaths.isNotEmpty)
          SliverSafeArea(
            top: false,
            minimum: const EdgeInsets.only(
              bottom: 70,
            ),
            sliver: MasonryFiles(
              crossAxisCount: crossAxisCount,
              files: filePaths,
              selectedFiles: selectedFiles,
            ),
          ),
        // Empty state at root
        if (filePaths.isEmpty && folders.isEmpty && currentPath != null)
          const SliverSafeArea(
            sliver: SliverToBoxAdapter(child: _NoFiles()),
          ),
      ],
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_outlined,
              size: 80,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              t.home.welcome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              t.home.createNewNote,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _PathBreadcrumb extends StatelessWidget {
  const _PathBreadcrumb({required this.path, required this.onTap});

  final String path;
  final void Function(String path) onTap;

  @override
  Widget build(BuildContext context) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => onTap(''),
              child: Text(
                t.home.rootDirectory,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            for (int i = 0; i < segments.length; i++) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16),
              ),
              GestureDetector(
                onTap: () => onTap('/${segments.sublist(0, i + 1).join('/')}'),
                child: Text(
                  segments[i],
                  style: TextStyle(
                    color: i == segments.length - 1
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: i == segments.length - 1
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoFiles extends StatelessWidget {
  const _NoFiles();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              t.home.noFiles,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsOverlay extends StatefulWidget {
  const _SettingsOverlay({required this.buttonRect});

  final Rect buttonRect;

  @override
  State<_SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<_SettingsOverlay> {
  Orientation? _lastOrientation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentOrientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != null && _lastOrientation != currentOrientation) {
      Navigator.of(context).pop();
    }
    _lastOrientation = currentOrientation;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const maxWidth = 350.0;
    const maxHeight = 500.0;

    double top = widget.buttonRect.bottom + 8;
    double left = widget.buttonRect.right - maxWidth;

    if (left < 16) left = 16;
    if (left + maxWidth > screenSize.width - 16) {
      left = screenSize.width - maxWidth - 16;
    }
    if (top + maxHeight > screenSize.height - 16) {
      top = widget.buttonRect.top - maxHeight - 8;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: left,
          top: top,
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const SettingsContent(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
