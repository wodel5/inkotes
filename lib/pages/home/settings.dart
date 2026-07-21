import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foledge/components/settings/settings_dropdown.dart';
import 'package:foledge/components/settings/settings_selection.dart';
import 'package:foledge/components/settings/settings_switch.dart';
import 'package:foledge/components/theming/adaptive_alert_dialog.dart';
import 'package:foledge/components/theming/adaptive_toggle_buttons.dart';
import 'package:foledge/data/locales.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:stow/stow.dart';

abstract class SettingsPage {
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
}

/// Reusable settings content widget that can be embedded in a dialog or page.
class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
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
    return Column(
      children: [
        SettingsDropdown(
          title: t.settings.prefLabels.locale,
          icon: FontAwesomeIcons.globe,
          pref: stows.locale,
          options: [
            ...AppLocaleUtils.supportedLocales.map((locale) {
              final localeCode = locale.toLanguageTag();
              final localeName = localeNames[localeCode];
              assert(localeName != null, 'Missing locale name for $localeCode');
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
            if (i == ThemeMode.system.index) {
              return FontAwesomeIcons.circleHalfStroke;
            }
            if (i == ThemeMode.light.index) return FontAwesomeIcons.solidSun;
            if (i == ThemeMode.dark.index) return FontAwesomeIcons.solidMoon;
            return null;
          },
          pref: _SettingsStows.appTheme,
          optionsWidth: 60,
          options: [
            ToggleButtonsOption(
              ThemeMode.system.index,
              FaIcon(FontAwesomeIcons.circleHalfStroke, size: 20),
            ),
            ToggleButtonsOption(
              ThemeMode.light.index,
              FaIcon(FontAwesomeIcons.solidSun, size: 20),
            ),
            ToggleButtonsOption(
              ThemeMode.dark.index,
              FaIcon(FontAwesomeIcons.solidMoon, size: 20),
            ),
          ],
        ),
        SettingsSwitch(
          title:
              t.settings.prefLabels.autoDisableFingerDrawingWhenStylusDetected,
          subtitle: t
              .settings
              .prefDescriptions
              .autoDisableFingerDrawingWhenStylusDetected,
          icon: IconData(0xe7de, fontFamily: 'iconfont'),
          pref: stows.autoDisableFingerDrawingWhenStylusDetected,
        ),
        SettingsSwitch(
          title: t.settings.prefLabels.printPageIndicators,
          subtitle: t.settings.prefDescriptions.printPageIndicators,
          icon: FontAwesomeIcons.hashtag,
          pref: stows.printPageIndicators,
        ),
        SettingsSwitch(
          title: '自动切换画纸颜色',
          icon: Icons.palette_outlined,
          pref: stows.autoSwitchPaperColor,
        ),
        SettingsSelection(
          title: t.settings.prefLabels.autosave,
          subtitle: t.settings.prefDescriptions.autosave,
          icon: FontAwesomeIcons.solidFloppyDisk,
          pref: stows.autosaveDelay,
          optionsWidth: 60,
          options: [
            const ToggleButtonsOption(5000, Text('5s')),
            const ToggleButtonsOption(10000, Text('10s')),
            ToggleButtonsOption(-1, Text(t.settings.autosaveDisabled)),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    stows.locale.removeListener(onChanged);
    super.dispose();
  }
}
