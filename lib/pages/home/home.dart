import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';
import 'package:logging/logging.dart';
import 'package:inkotes/components/common/app_toast.dart';
import 'package:inkotes/components/home/masonry_files.dart';
import 'package:inkotes/data/file_manager/file_importer.dart';
import 'package:inkotes/data/file_manager/file_manager.dart';
import 'package:inkotes/data/file_manager/file_trash_manager.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/routes.dart';
import 'package:inkotes/data/update_service.dart';
import 'package:inkotes/i18n/strings.g.dart';
import 'package:inkotes/pages/editor/editor.dart';
import 'package:inkotes/pages/home/widgets/home_bottom_dock.dart';
import 'package:inkotes/pages/home/widgets/no_files.dart';

class HomePage extends StatefulHookWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final log = Logger('HomePage');

  /// All files (notes) at the current path level
  final List<String> filePaths = [];

  var failed = false;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  // Rename-in-dock state
  var _isRenaming = false;
  final _renameController = TextEditingController();
  String? _renameError;

  // Search state
  var _isSearching = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
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

    // 自动检查更新（当前为模拟实现）
    checkForUpdates();

    super.initState();
  }

  /// 触发更新检查，有新版本时主页设置按钮显示红点。
  void checkForUpdates() async {
    await UpdateService.checkForUpdates(source: stows.updateSource.value);
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
    fileWriteSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _renameController.dispose();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  void fileWriteListener(FileOperation event) {
    findChildren(fromFileListener: true);
  }

  void _setState() {
    if (selectedFiles.value.isEmpty && _isRenaming) {
      _isRenaming = false;
      _renameError = null;
    }
    setState(() {});
  }

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

    // Show recent files at root
    final recentFiles = await FileManager.getRecentlyAccessed();
    // Filter out trashed files
    final nonTrashedFiles = await FileTrashManager.filterOutTrashed(recentFiles);
    filePaths.clear();
    if (nonTrashedFiles.isEmpty) {
      failed = true;
    } else {
      failed = false;
      filePaths.addAll(nonTrashedFiles);
    }

    if (mounted) setState(() {});
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchController.clear();
      _searchResults = [];
    });
    _searchFocusNode.requestFocus();
    FileManager.getAllFiles().then((files) {
      _allFiles = files;
    });
  }

  void _stopSearch() {
    _searchFocusNode.unfocus();
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

  void startRename() {
    final path = selectedFiles.value.first;
    _renameController.text = path.substring(path.lastIndexOf('/') + 1);
    _renameError = null;
    setState(() => _isRenaming = true);
  }

  void cancelRename() {
    _renameController.clear();
    _renameError = null;
    setState(() => _isRenaming = false);
  }

  Future<void> confirmRename() async {
    final newName = _renameController.text.trim();
    final path = selectedFiles.value.first;
    final parentFolder = path.substring(0, path.lastIndexOf('/') + 1);
    final oldName = path.substring(path.lastIndexOf('/') + 1);

    if (newName.isEmpty) {
      setState(() => _renameError = t.home.renameNote.noteNameEmpty);
      return;
    }
    final error = FileManager.validateFilename(newName);
    if (error != null) {
      setState(() => _renameError = error);
      return;
    }
    if (newName != oldName && File('$parentFolder$newName').existsSync()) {
      setState(() => _renameError = t.home.renameNote.noteNameExists);
      return;
    }

    if (newName != oldName) {
      await FileManager.moveFile(
        path + Editor.extension,
        newName + Editor.extension,
      );
    }
    cancelRename();
    selectedFiles.value = [];
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
    final noteFilePath = await FileManager.suffixFilePathToMakeItUnique(
      '/$fileNameWithoutExtension',
    );
    if (!mounted) return;
    context.push(RoutePaths.editImportPdf(noteFilePath, filePath));
  }

  Future<void> _importNote() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      allowMultiple: false,
      withData: false,
    );
    if (result == null || !mounted) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    final importedPath = await FileImporter.importFile(
      filePath,
      '/',
      extension: '.zip',
    );
    if (!mounted) return;

    if (importedPath != null) {
      AppToast.show(context, message: t.home.import.success);
      context.push(RoutePaths.editFilePath(importedPath));
    } else {
      AppToast.show(context, message: t.home.import.invalidFile, isError: true, duration: const Duration(seconds: 4));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final isLandscape = MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final crossAxisCount = isLandscape ? 4 : 2;

    return GestureDetector(
      onTap: () {
        if (_isRenaming) cancelRename();
        if (selectedFiles.value.isNotEmpty) {
          selectedFiles.value = [];
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
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
                  focusNode: _searchFocusNode,
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
                              selectedFiles.value = [];
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
                                      leading: const SizedBox(width: 24, child: Center(child: FaIcon(FontAwesomeIcons.fileCirclePlus))),
                                      title: Text(t.home.create.newNote, style: const TextStyle(fontSize: 16)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'import',
                                    child: ListTile(
                                      leading: const SizedBox(width: 24, child: Center(child: FaIcon(FontAwesomeIcons.fileImport))),
                                      title: Text(t.home.create.importNote, style: const TextStyle(fontSize: 16)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'pdf',
                                    child: ListTile(
                                      leading: const SizedBox(width: 24, child: Center(child: FaIcon(FontAwesomeIcons.solidFilePdf))),
                                      title: Text(t.home.importPdf, style: const TextStyle(fontSize: 16)),
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ).then((value) async {
                                if (value == 'create') {
                                  final router = GoRouter.of(context);
                                  final newFilePath = await FileImporter.newFilePath(
                                    '/',
                                  );
                                  if (!mounted) return;
                                  router.push(RoutePaths.editFilePath(newFilePath));
                                } else if (value == 'import') {
                                  _importNote();
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
                          onPressed: () {
                            selectedFiles.value = [];
                            _startSearch();
                          },
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
                              selectedFiles.value = [];
                              context.push(RoutePaths.trash);
                            },
                          ),
                        ),
                      ),
                      // Settings button (fades out when searching)
                      AnimatedOpacity(
                        opacity: _isSearching ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: UpdateService.hasNewVersion,
                          builder: (context, hasNewVersion, _) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  icon: const FaIcon(FontAwesomeIcons.gear),
                                  onPressed: () {
                                    selectedFiles.value = [];
                                    context.push(RoutePaths.settings);
                                  },
                                ),
                                // 有新版本时的红点提示
                                if (hasNewVersion)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: _isSearching ? _buildSearchResults() : _buildBody(crossAxisCount),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: HomeBottomDock(
              selectedFiles: selectedFiles,
              filePaths: filePaths,
              isRenaming: _isRenaming,
              renameController: _renameController,
              renameError: _renameError,
              onStartRename: startRename,
              onCancelRename: cancelRename,
              onConfirmRename: confirmRename,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Text(t.home.searchNoResults),
      );
    }

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
    if (failed) {
      return _buildWelcome();
    }

    return CustomScrollView(
      slivers: [
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
        // Empty state
        if (filePaths.isEmpty)
          const SliverSafeArea(
            sliver: SliverToBoxAdapter(child: NoFiles()),
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
