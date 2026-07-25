import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:foledge/components/settings/settings_dropdown.dart';
import 'package:foledge/components/settings/settings_selection.dart';
import 'package:foledge/components/settings/settings_switch.dart';
import 'package:foledge/components/theming/adaptive_toggle_buttons.dart';
import 'package:foledge/data/locales.dart';
import 'package:foledge/data/prefs.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:stow/stow.dart';

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
          icon: Icons.language_rounded,
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
              return Icons.brightness_auto_rounded;
            }
            if (i == ThemeMode.light.index) return Icons.brightness_high_rounded;
            if (i == ThemeMode.dark.index) return FontAwesomeIcons.solidMoon;
            return null;
          },
          pref: _SettingsStows.appTheme,
          optionsWidth: 60,
          options: [
            ToggleButtonsOption(
              ThemeMode.system.index,
              const Icon(Icons.brightness_auto_rounded, size: 26),
            ),
            ToggleButtonsOption(
              ThemeMode.light.index,
              const Icon(Icons.brightness_high_rounded, size: 26),
            ),
            ToggleButtonsOption(
              ThemeMode.dark.index,
              const FaIcon(FontAwesomeIcons.solidMoon, size: 20),
            ),
          ],
        ),
        SettingsSwitch(
          title:
              t.settings.prefLabels.autoDisableFingerDrawingWhenStylusDetected,
          icon: const IconData(0xe7de, fontFamily: 'iconfont'),
          pref: stows.autoDisableFingerDrawingWhenStylusDetected,
        ),
        SettingsSwitch(
          title: t.settings.prefLabels.autoSwitchPaperColor,
          icon: FontAwesomeIcons.circleHalfStroke,
          pref: stows.autoSwitchPaperColor,
        ),
        SettingsSwitch(
          title: t.settings.prefLabels.printPageIndicators,
          icon: FontAwesomeIcons.hashtag,
          pref: stows.printPageIndicators,
        ),
        SettingsSelection(
          title: t.settings.prefLabels.autosave,
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
