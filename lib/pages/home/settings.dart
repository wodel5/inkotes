import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:foledge/components/navbar/responsive_navbar.dart';
import 'package:foledge/components/settings/settings_button.dart';
import 'package:foledge/components/settings/settings_directory_selector.dart';
import 'package:foledge/components/settings/settings_dropdown.dart';
import 'package:foledge/components/settings/settings_selection.dart';
import 'package:foledge/components/settings/settings_sentry.dart';
import 'package:foledge/components/settings/settings_subtitle.dart';
import 'package:foledge/components/settings/settings_switch.dart';
import 'package:foledge/components/theming/adaptive_alert_dialog.dart';
import 'package:foledge/components/theming/adaptive_toggle_buttons.dart';
import 'package:foledge/data/locales.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/data/routes.dart';
import 'package:foledge/data/sentry/sentry_init.dart';
import 'package:foledge/data/tools/shape_pen.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:stow/stow.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Future<bool?> showResetDialog({
    required BuildContext context,
    required Stow pref,
    required String prefTitle,
  }) async {
    if (pref.value == pref.defaultValue) return null;
    return await showDialog(
      context: context,
      builder: (context) => AdaptiveAlertDialog(
        title: Text(t.settings.reset.title),
        content: Text(prefTitle),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              pref.value = pref.defaultValue;
              Navigator.of(context).pop(true);
            },
            child: Text(t.settings.reset.button),
          ),
        ],
      ),
    );
  }
}

abstract class _SettingsStows {
  static final appTheme = TransformedStow(
    stows.appTheme,
    (ThemeMode value) => value.index,
    (int value) => ThemeMode.values[value],
  );

  static final layoutSize = TransformedStow(
    stows.layoutSize,
    (LayoutSize value) => value.index,
    (int value) => LayoutSize.values[value],
  );
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    stows.locale.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const .only(bottom: 8),
            sliver: SliverAppBar(
              collapsedHeight: kToolbarHeight,
              expandedHeight: 200,
              pinned: true,
              scrolledUnderElevation: 1,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  t.home.titles.settings,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 16,
                  bottom: 16,
                ),
              ),
            ),
          ),
          SliverSafeArea(
            sliver: SliverList.list(
              children: [
                SettingsSubtitle(subtitle: t.settings.prefCategories.general),
                SettingsDropdown(
                  title: t.settings.prefLabels.locale,
                  icon: Icons.language,
                  pref: stows.locale,
                  options: [
                    ...AppLocaleUtils.supportedLocales.map((locale) {
                      final localeCode = locale.toLanguageTag();
                      final localeName = localeNames[localeCode];
                      assert(
                        localeName != null,
                        'Missing locale name for $localeCode',
                      );
                      return ToggleButtonsOption(
                        localeCode,
                        Text(localeName ?? localeCode),
                      );
                    }),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.appTheme,
                  iconBuilder: (i) {
                    if (i == ThemeMode.system.index)
                      return Icons.brightness_auto;
                    if (i == ThemeMode.light.index) return Icons.light_mode;
                    if (i == ThemeMode.dark.index) return Icons.dark_mode;
                    return null;
                  },
                  pref: _SettingsStows.appTheme,
                  optionsWidth: 60,
                  options: [
                    ToggleButtonsOption(
                      ThemeMode.system.index,
                      Icon(
                        Icons.brightness_auto,
                        semanticLabel: t.settings.themeModes.system,
                      ),
                    ),
                    ToggleButtonsOption(
                      ThemeMode.light.index,
                      Icon(
                        Icons.light_mode,
                        semanticLabel: t.settings.themeModes.light,
                      ),
                    ),
                    ToggleButtonsOption(
                      ThemeMode.dark.index,
                      Icon(
                        Icons.dark_mode,
                        semanticLabel: t.settings.themeModes.dark,
                      ),
                    ),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.layoutSize,
                  subtitle: switch (stows.layoutSize.value) {
                    .auto => t.settings.layoutSizes.auto,
                    .phone => t.settings.layoutSizes.phone,
                    .tablet => t.settings.layoutSizes.tablet,
                  },
                  afterChange: (_) => setState(() {}),
                  iconBuilder: (i) => switch (LayoutSize.values[i]) {
                    .auto => Icons.aspect_ratio,
                    .phone => Icons.smartphone,
                    .tablet => Icons.tablet,
                  },
                  pref: _SettingsStows.layoutSize,
                  optionsWidth: 60,
                  options: [
                    ToggleButtonsOption(
                      LayoutSize.auto.index,
                      Icon(
                        Icons.aspect_ratio,
                        semanticLabel: t.settings.layoutSizes.auto,
                      ),
                    ),
                    ToggleButtonsOption(
                      LayoutSize.phone.index,
                      Icon(
                        Icons.smartphone,
                        semanticLabel: t.settings.layoutSizes.phone,
                      ),
                    ),
                    ToggleButtonsOption(
                      LayoutSize.tablet.index,
                      Icon(
                        Icons.tablet,
                        semanticLabel: t.settings.layoutSizes.tablet,
                      ),
                    ),
                  ],
                ),
                SettingsSubtitle(subtitle: t.settings.prefCategories.writing),
                SettingsSwitch(
                  title: t
                      .settings
                      .prefLabels
                      .autoDisableFingerDrawingWhenStylusDetected,
                  subtitle: t
                      .settings
                      .prefDescriptions
                      .autoDisableFingerDrawingWhenStylusDetected,
                  icon: CupertinoIcons.pencil,
                  pref: stows.autoDisableFingerDrawingWhenStylusDetected,
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.autoClearWhiteboardOnExit,
                  subtitle:
                      t.settings.prefDescriptions.autoClearWhiteboardOnExit,
                  icon: Icons.cleaning_services,
                  pref: stows.autoClearWhiteboardOnExit,
                ),
                SettingsSubtitle(subtitle: t.settings.prefCategories.editor),
                SettingsSelection(
                  title: t.settings.prefLabels.recentColorsLength,
                  icon: Icons.history,
                  pref: stows.recentColorsLength,
                  options: const [
                    ToggleButtonsOption(5, Text('5')),
                    ToggleButtonsOption(10, Text('10')),
                  ],
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.printPageIndicators,
                  subtitle: t.settings.prefDescriptions.printPageIndicators,
                  icon: Icons.numbers,
                  pref: stows.printPageIndicators,
                ),
                SettingsSubtitle(
                  subtitle: t.settings.prefCategories.performance,
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.maxImageSize,
                  subtitle: t.settings.prefDescriptions.maxImageSize,
                  icon: Icons.photo_size_select_large,
                  pref: stows.maxImageSize,
                  options: const <ToggleButtonsOption<double>>[
                    ToggleButtonsOption(500, Text('500')),
                    ToggleButtonsOption(1000, Text('1000')),
                    ToggleButtonsOption(2000, Text('2000')),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.autosave,
                  subtitle: t.settings.prefDescriptions.autosave,
                  icon: Icons.save,
                  pref: stows.autosaveDelay,
                  options: [
                    const ToggleButtonsOption(5000, Text('5s')),
                    const ToggleButtonsOption(10000, Text('10s')),
                    ToggleButtonsOption(-1, Text(t.settings.autosaveDisabled)),
                  ],
                ),
                SettingsSelection(
                  title: t.settings.prefLabels.shapeRecognitionDelay,
                  subtitle: t.settings.prefDescriptions.shapeRecognitionDelay,
                  icon: FontAwesomeIcons.shapes,
                  pref: stows.shapeRecognitionDelay,
                  options: [
                    const ToggleButtonsOption(500, Text('0.5s')),
                    const ToggleButtonsOption(1000, Text('1s')),
                    ToggleButtonsOption(
                      -1,
                      Text(t.settings.shapeRecognitionDisabled),
                    ),
                  ],
                  afterChange: (ms) {
                    ShapePen.debounceDuration = ShapePen.getDebounceFromPref();
                  },
                ),
                SettingsSwitch(
                  title: t.settings.prefLabels.autoStraightenLines,
                  subtitle: t.settings.prefDescriptions.autoStraightenLines,
                  icon: Icons.straighten,
                  pref: stows.autoStraightenLines,
                ),
                SettingsSubtitle(subtitle: t.settings.prefCategories.advanced),
                if (isSentryAvailable) const SettingsSentryConsent(),
                if (Platform.isAndroid)
                  SettingsDirectorySelector(
                    title: t.settings.prefLabels.customDataDir,
                    icon: Icons.folder,
                  ),
                SettingsSwitch(
                  title: t.settings.prefLabels.allowInsecureConnections,
                  subtitle:
                      t.settings.prefDescriptions.allowInsecureConnections,
                  icon: Icons.private_connectivity,
                  pref: stows.allowInsecureConnections,
                ),
                SettingsButton(
                  title: t.logs.viewLogs,
                  subtitle: t.logs.debuggingInfo,
                  icon: Icons.receipt_long,
                  onPressed: () => context.push(RoutePaths.logs),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stows.locale.removeListener(onChanged);
    super.dispose();
  }
}
