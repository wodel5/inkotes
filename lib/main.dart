import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';
import 'package:printing/printing.dart';
import 'package:foledge/components/canvas/pencil_shader.dart';
import 'package:foledge/components/theming/dynamic_material_app.dart';
import 'package:foledge/data/file_manager/file_manager.dart';
import 'package:foledge/data/flavor_config.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/data/routes.dart';
import 'package:foledge/data/tools/stroke_properties.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:foledge/pages/editor/editor.dart';
import 'package:foledge/pages/home/home.dart';

import 'package:worker_manager/worker_manager.dart';


Future<void> main(List<String> args) async {
  FlavorConfig.setupFromEnvironment();
  await appRunner(args);
}

Future<void> appRunner(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final parser = ArgParser()..addFlag('verbose', abbr: 'v', negatable: false);
  final parsedArgs = parser.parse(args);

  Logger.root.level = (kDebugMode || parsedArgs.flag('verbose'))
      ? Level.INFO
      : Level.WARNING;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });

  if (!kDebugMode) {
    final errorLogger = Logger('ErrorLogger');
    FlutterError.onError = (details) {
      errorLogger.severe(
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      errorLogger.severe(error, stackTrace);
      return !kDebugMode;
    };
  }

  StrokeOptionsExtension.setDefaults();
  Stows.markAsOnMainIsolate();

  await Future.wait([
    FileManager.init(),
    workerManager.init(
      isolatesCount: kDebugMode ? 1 : 2,
    ),
    stows.locale.waitUntilRead(),
    PencilShader.init(),
    Printing.info().then((info) {
      Editor.canRasterPdf = info.canRaster;
    }),
  ]);

  setLocale();
  stows.locale.addListener(setLocale);
  pdfrxFlutterInitialize();

  LicenseRegistry.addLicense(() async* {
    for (final licenseFile in const [
      'assets/google_fonts/Atkinson_Hyperlegible_Next/OFL.txt',
      'assets/google_fonts/Dekko/OFL.txt',
      'assets/google_fonts/Fira_Mono/OFL.txt',
      'assets/google_fonts/Neucha/OFL.txt',
    ]) {
      final license = await rootBundle.loadString(licenseFile);
      yield LicenseEntryWithLineBreaks(const ['google_fonts'], license);
    }
  });

  runApp(TranslationProvider(child: const App()));
}

void setLocale() {
  if (stows.locale.value.isNotEmpty &&
      AppLocaleUtils.supportedLocalesRaw.contains(stows.locale.value)) {
    LocaleSettings.setLocaleRaw(stows.locale.value);
  } else {
    stows.locale.value = 'zh-Hans-CN';
    LocaleSettings.setLocale(AppLocale.zhHansCn);
  }
}

class App extends StatefulWidget {
  const App({super.key});

  static final log = Logger('App');

  static final _router = GoRouter(
    initialLocation: RoutePaths.home,
    routes: <GoRoute>[
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RoutePaths.edit,
        builder: (context, state) => Editor(
          path: state.uri.queryParameters['path'],
          pdfPath: state.uri.queryParameters['pdfPath'],
        ),
      ),
    ],
  );

  static void openFile(SharedFile file) async {
    final filePath = file.value;
    if (file.type != SharedMediaType.FILE || filePath == null) return;
    log.info('Opening file: (${file.type}) $filePath');

    var extension = p.extension(filePath);
    if (extension.isEmpty) {
      extension = '.sbn2';
    }

    if (extension == '.sbn' || extension == '.sbn2' || extension == '.sba') {
      final path = await FileManager.importFile(
        filePath,
        null,
        extension: extension,
      );
      if (path == null) return;

      await Future.delayed(const Duration(milliseconds: 100));

      _router.push(RoutePaths.editFilePath(path));
    } else if (extension == '.pdf' && Editor.canRasterPdf) {
      final fileNameWithoutExtension = p.basenameWithoutExtension(filePath);
      final sbnFilePath = await FileManager.suffixFilePathToMakeItUnique(
        '/$fileNameWithoutExtension',
      );
      _router.push(RoutePaths.editImportPdf(sbnFilePath, filePath));
    } else {
      log.warning('openFile: Unsupported file type: $extension');
    }
  }

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    setupSharingIntent();
    super.initState();
  }

  void setupSharingIntent() {
    if (Platform.isAndroid || Platform.isIOS) {
      FlutterSharingIntent.instance.getInitialSharing().then((
        List<SharedFile> files,
      ) {
        for (final file in files) {
          App.openFile(file);
        }
      });

      final stream = FlutterSharingIntent.instance.getMediaStream();
      _intentDataStreamSubscription = stream.listen((List<SharedFile> files) {
        for (final file in files) {
          App.openFile(file);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicMaterialApp(title: 'Foledge', router: App._router);
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }
}
