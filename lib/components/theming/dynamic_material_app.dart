import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:go_router/go_router.dart';
import 'package:inkotes/components/theming/inkotes_color_schemes.dart';
import 'package:inkotes/components/theming/inkotes_theme.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/i18n/extensions/redirecting_localization_delegate.dart';
import 'package:inkotes/i18n/strings.g.dart';

class DynamicMaterialApp extends StatefulHookWidget {
  const DynamicMaterialApp({
    super.key,
    required this.title,
    required this.router,
  });

  final String title;
  final GoRouter router;

  @override
  State<DynamicMaterialApp> createState() => DynamicMaterialAppState();
}

class DynamicMaterialAppState extends State<DynamicMaterialApp> {
  @override
  Widget build(BuildContext context) {
    final themeMode = useValueListenable(stows.appTheme);

    final platform = Theme.of(context).platform;

    return ExplicitlyThemedApp(
      title: widget.title,
      router: widget.router,
      themeMode: themeMode,
      theme: InkotesTheme.createTheme(InkotesColorSchemes.light, platform),
      darkTheme: InkotesTheme.createTheme(InkotesColorSchemes.dark, platform),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIChangeCallback(null);

    super.dispose();
  }
}

@visibleForTesting
class ExplicitlyThemedApp extends StatelessWidget {
  @protected
  const ExplicitlyThemedApp({
    super.key,
    required this.title,
    required this.router,
    required this.themeMode,
    required this.theme,
    required this.darkTheme,
    this.highContrastTheme,
    this.highContrastDarkTheme,
  });

  final String title;
  final GoRouter router;
  final ThemeMode themeMode;
  final ThemeData theme;
  final ThemeData? darkTheme, highContrastTheme, highContrastDarkTheme;

  static final _materialAppKey = GlobalKey<State<MaterialApp>>();

  @override
  Widget build(BuildContext context) {
    final highContrastTheme =
        this.highContrastTheme ??
        theme.copyWith(colorScheme: theme.colorScheme.withHighContrast());
    final highContrastDarkTheme =
        this.highContrastDarkTheme ??
        darkTheme?.copyWith(
          colorScheme: darkTheme?.colorScheme.withHighContrast(),
        );

    return MaterialApp.router(
      key: _materialAppKey,
      title: title,
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
      locale: TranslationProvider.of(context).flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: const [
        RedirectingLocalizationDelegate<CupertinoLocalizations>(
          GlobalCupertinoLocalizations.delegate,
        ),
        RedirectingLocalizationDelegate<MaterialLocalizations>(
          GlobalMaterialLocalizations.delegate,
        ),
        RedirectingLocalizationDelegate<WidgetsLocalizations>(
          GlobalWidgetsLocalizations.delegate,
        ),
        RedirectingLocalizationDelegate<FlutterQuillLocalizations>(
          FlutterQuillLocalizations.delegate,
        ),
      ],
      themeMode: themeMode,
      theme: theme,
      darkTheme: darkTheme,
      highContrastTheme: highContrastTheme,
      highContrastDarkTheme: highContrastDarkTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}

extension on ColorScheme {
  ColorScheme withHighContrast() => ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: primary,
    surface: brightness == .light ? Colors.white : Colors.black,
    contrastLevel: 1,
  );
}
