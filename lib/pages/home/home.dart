import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:yaru/yaru.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:foledge/components/home/grid_folders.dart';
import 'package:foledge/components/home/masonry_files.dart';
import 'package:foledge/components/theming/adaptive_alert_dialog.dart';
import 'package:foledge/components/theming/adaptive_text_field.dart';
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

    super.initState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_setState);
    fileWriteSubscription?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                if (currentPath != null)
                  _PathBreadcrumb(
                    path: currentPath!,
                    onTap: (path) {
                      currentPath = path.isEmpty ? null : path;
                      findChildren();
                    },
                  ),
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
            child: SafeArea(
              top: false,
              child: Opacity(
                opacity: selectedFiles.value.isEmpty ? 0 : 1,
                child: IgnorePointer(
                  ignoring: selectedFiles.value.isEmpty,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.light
                                  ? const Color(0xFF9999BB).withValues(alpha: 0.15)
                                  : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: IntrinsicWidth(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (selectedFiles.value.length == 1)
                                    _HomeDockButton(
                                      icon: FontAwesomeIcons.squarePen,
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return _RenameNoteDialog(
                                              existingPath: selectedFiles.value.first,
                                              unselectNotes: () => selectedFiles.value = [],
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  _HomeDockButton(
                                    icon: Icons.drive_file_move,
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return _MoveNoteDialog(
                                            filesToMove: selectedFiles.value,
                                            unselectNotes: () => selectedFiles.value = [],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  _HomeDockButton(
                                    icon: FontAwesomeIcons.trash,
                                    onPressed: () async {
                                      await showDialog(
                                        context: context,
                                        builder: (context) => _DeleteNoteDialog(
                                          filesToDelete: selectedFiles.value,
                                          unselectNotes: () => selectedFiles.value = [],
                                        ),
                                      );
                                    },
                                  ),
                                  _HomeDockButton(
                                    icon: FontAwesomeIcons.shareNodes,
                                    onPressed: () {
                                      // TODO: implement export
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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

class _HomeDockButton extends StatefulWidget {
  const _HomeDockButton({
    required this.icon,
    required this.onPressed,
  });

  final Object icon;
  final VoidCallback? onPressed;

  @override
  State<_HomeDockButton> createState() => _HomeDockButtonState();
}

class _HomeDockButtonState extends State<_HomeDockButton> {
  bool _pressing = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final brightness = Theme.of(context).brightness;

    final iconColor = colorScheme.onSurface;

    Color? backgroundColor;
    if (_pressing) {
      backgroundColor = brightness == Brightness.light
          ? Colors.grey.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.1);
    }

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => setState(() => _pressing = true) : null,
      onTapUp: widget.onPressed != null ? (_) => setState(() => _pressing = false) : null,
      onTapCancel: () => setState(() => _pressing = false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(color: iconColor, size: 20),
            child: widget.icon is IconData
                ? Icon(widget.icon as IconData)
                : FaIcon(widget.icon as FaIconData),
          ),
        ),
      ),
    );
  }
}

class _RenameNoteDialog extends StatefulWidget {
  const _RenameNoteDialog({
    required this.existingPath,
    required this.unselectNotes,
  });

  final String existingPath;
  final void Function() unselectNotes;

  @override
  State<_RenameNoteDialog> createState() => _RenameNoteDialogState();
}

class _RenameNoteDialogState extends State<_RenameNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  late final parentFolder = widget.existingPath.substring(
    0,
    widget.existingPath.lastIndexOf('/') + 1,
  );
  late final oldName = widget.existingPath.substring(
    widget.existingPath.lastIndexOf('/') + 1,
  );

  String? validateNoteName(String? noteName) {
    if (noteName == null) return t.home.renameNote.noteNameEmpty;
    final error = FileManager.validateFilename(noteName);
    if (error != null) return error;
    if (noteName != oldName && doesFileExist(noteName)) {
      return t.home.renameNote.noteNameExists;
    }
    return null;
  }

  bool doesFileExist(String noteName) {
    final file = File(parentFolder + noteName);
    return file.existsSync();
  }

  Future renameNote(String newName) async {
    await FileManager.moveFile(
      widget.existingPath + Editor.extension,
      newName + Editor.extension,
    );
  }

  @override
  void initState() {
    super.initState();
    _controller.text = oldName;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveAlertDialog(
      title: Text(t.home.renameNote.renameNote),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AdaptiveTextField(
          controller: _controller,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          focusOrder: const NumericFocusOrder(1),
          placeholder: t.home.renameNote.noteName,
          prefixIcon: const Icon(Icons.edit_square),
          validator: validateNoteName,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(t.common.cancel),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            if (_controller.text != oldName) {
              await renameNote(_controller.text);
            }
            if (!context.mounted) return;
            Navigator.of(context).pop();
            widget.unselectNotes();
          },
          child: Text(t.home.renameNote.rename),
        ),
      ],
    );
  }
}

class _MoveNoteDialog extends StatefulWidget {
  const _MoveNoteDialog({
    required this.filesToMove,
    required this.unselectNotes,
  });

  final List<String> filesToMove;
  final void Function() unselectNotes;

  @override
  State<_MoveNoteDialog> createState() => _MoveNoteDialogState();
}

class _MoveNoteDialogState extends State<_MoveNoteDialog> {
  late final List<String> originalFileNames = widget.filesToMove
      .map((path) => path.substring(path.lastIndexOf('/') + 1))
      .toList();

  late final List<String> parentFolders = widget.filesToMove
      .map((path) => path.substring(0, path.lastIndexOf('/') + 1))
      .toList();

  late List<bool> oldExtensions = widget.filesToMove
      .map((name) => false)
      .toList();
  Future<void> findOldExtensions() async {
    oldExtensions = [
      for (int i = 0; i < widget.filesToMove.length; ++i)
        FileManager.doesFileExist(
          '${widget.filesToMove[i]}${Editor.extensionOldJson}',
        ),
    ];
  }

  late String _currentFolder;

  String get currentFolder => _currentFolder;
  set currentFolder(String folder) {
    _currentFolder = folder;
    currentFolderChildren = null;
    findChildrenOfCurrentFolder();
  }

  DirectoryChildren? currentFolderChildren;

  late List<String> newFileNames = [];

  late List<String> changedFileNames = [];

  Future findChildrenOfCurrentFolder() async {
    currentFolderChildren = await FileManager.getChildrenOfDirectory(
      currentFolder,
    );

    newFileNames = [];
    changedFileNames = [];
    for (int i = 0; i < widget.filesToMove.length; ++i) {
      final oldExtension = oldExtensions[i];
      final newFileName = await FileManager.suffixFilePathToMakeItUnique(
        '$currentFolder${originalFileNames[i]}',
        intendedExtension: oldExtension
            ? Editor.extensionOldJson
            : Editor.extension,
        currentPath:
            '${widget.filesToMove[i]}${oldExtension ? Editor.extensionOldJson : Editor.extension}',
      ).then((newPath) => newPath.substring(newPath.lastIndexOf('/') + 1));

      newFileNames.add(newFileName);

      if (newFileName != originalFileNames[i]) {
        changedFileNames.add(newFileName);
      }
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> createFolder(String folderName) async {
    final folderPath = '$currentFolder/$folderName';
    await FileManager.createFolder(folderPath);
    findChildrenOfCurrentFolder();
  }

  @override
  void initState() {
    currentFolder = _findMostCommonParentFolder();
    if (!currentFolder.startsWith('/')) {
      currentFolder = '/$currentFolder';
    }
    super.initState();

    findOldExtensions().then((_) => findChildrenOfCurrentFolder());
  }

  String _findMostCommonParentFolder() {
    final parentFolderCounts = <String, int>{};
    for (final parentFolder in parentFolders) {
      parentFolderCounts[parentFolder] =
          (parentFolderCounts[parentFolder] ?? 0) + 1;
    }
    return parentFolderCounts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveAlertDialog(
      title: originalFileNames.length < 5
          ? Text(t.home.moveNote.moveName(f: originalFileNames.join(', ')))
          : Text(t.home.moveNote.moveNotes(n: originalFileNames.length)),
      content: SizedBox(
        width: 300,
        height: 300,
        child: Column(
          children: [
            Text(currentFolder),
            Expanded(
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: [
                  GridFolders(
                    isAtRoot: currentFolder == '/',
                    crossAxisCount: 3,
                    onTap: (String folder) {
                      setState(() {
                        if (folder == '..') {
                          currentFolder = currentFolder.substring(
                            0,
                            currentFolder.lastIndexOf(
                                  '/',
                                  currentFolder.length - 2,
                                ) +
                                1,
                          );
                        } else {
                          currentFolder = '$currentFolder$folder/';
                        }
                      });
                    },
                    createFolder: createFolder,
                    doesFolderExist: (String folderName) {
                      return currentFolderChildren?.directories.contains(
                            folderName,
                          ) ??
                          false;
                    },
                    renameFolder: (String oldName, String newName) async {
                      final oldPath = '$currentFolder$oldName';
                      await FileManager.renameDirectory(oldPath, newName);
                      findChildrenOfCurrentFolder();
                    },
                    isFolderEmpty: (String folderName) async {
                      final folderPath = '$currentFolder$folderName';
                      final children = await FileManager.getChildrenOfDirectory(
                        folderPath,
                      );
                      return children?.isEmpty ?? true;
                    },
                    deleteFolder: (String folderName) async {
                      final folderPath = '$currentFolder$folderName';
                      await FileManager.deleteDirectory(folderPath);
                      findChildrenOfCurrentFolder();
                    },
                    folders: [
                      for (final directoryPath
                          in currentFolderChildren?.directories ?? const [])
                        directoryPath,
                    ],
                  ),
                ],
              ),
            ),
            if (changedFileNames.isEmpty)
              const SizedBox.shrink()
            else if (changedFileNames.length == 1)
              Text(t.home.moveNote.renamedTo(newName: changedFileNames.single))
            else if (changedFileNames.length < 5) ...[
              Text(t.home.moveNote.multipleRenamedTo),
              Text(changedFileNames.join(', ')),
            ] else
              Text(t.home.moveNote.numberRenamedTo(n: changedFileNames.length)),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(t.common.cancel),
        ),
        CupertinoDialogAction(
          onPressed: () async {
            for (int i = 0; i < widget.filesToMove.length; ++i) {
              final extension = oldExtensions[i]
                  ? Editor.extensionOldJson
                  : Editor.extension;
              await FileManager.moveFile(
                '${widget.filesToMove[i]}$extension',
                '$currentFolder${newFileNames[i]}$extension',
              );
            }
            widget.unselectNotes();
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: Text(t.home.moveNote.move),
        ),
      ],
    );
  }
}

class _DeleteNoteDialog extends StatefulWidget {
  const _DeleteNoteDialog({
    required this.filesToDelete,
    required this.unselectNotes,
  });

  final List<String> filesToDelete;
  final void Function() unselectNotes;

  @override
  State<_DeleteNoteDialog> createState() => _DeleteNoteDialogState();
}

class _DeleteNoteDialogState extends State<_DeleteNoteDialog> {
  var deleteAllowed = false;

  @override
  Widget build(BuildContext context) {
    return AdaptiveAlertDialog(
      title: widget.filesToDelete.length < 5
          ? Text(
              t.home.deleteNoteDialog.deleteName(
                f: widget.filesToDelete.join(', '),
              ),
            )
          : Text(
              t.home.deleteNoteDialog.deleteNotes(
                n: widget.filesToDelete.length,
              ),
            ),
      content: CheckboxListTile.adaptive(
        value: deleteAllowed,
        onChanged: (value) => setState(() => deleteAllowed = value!),
        controlAffinity: .leading,
        title: Text(
          t.home.deleteNoteDialog.confirmDelete(n: widget.filesToDelete.length),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        CupertinoDialogAction(
          onPressed: deleteAllowed
              ? () async {
                  await Future.wait([
                    for (final String filePath in widget.filesToDelete)
                      Future.value(
                        FileManager.doesFileExist(
                          filePath + Editor.extensionOldJson,
                        ),
                      ).then(
                        (oldExtension) => FileManager.deleteFile(
                          filePath +
                              (oldExtension
                                  ? Editor.extensionOldJson
                                  : Editor.extension),
                        ),
                      ),
                  ]);
                  if (context.mounted) Navigator.of(context).pop();
                  widget.unselectNotes();
                }
              : null,
          isDestructiveAction: true,
          child: Text(t.home.deleteNoteDialog.delete),
        ),
      ],
    );
  }
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
