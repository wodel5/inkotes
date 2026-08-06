import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/settings/settings_dropdown.dart';
import 'package:inkotes/components/settings/settings_selection.dart';
import 'package:inkotes/components/settings/settings_switch.dart';
import 'package:inkotes/components/theming/adaptive_toggle_buttons.dart';
import 'package:inkotes/components/theming/uni_icon.dart';
import 'package:inkotes/data/locales.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/i18n/strings.g.dart';

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

/// Full-screen settings page.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.home.titles.settings),
      ),
      body: const SettingsContent(),
    );
  }
}

class _SettingsContentState extends State<SettingsContent> {
  static const appVersion = '0.1.0-beta1';

  @override
  void initState() {
    stows.locale.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  void _showAboutDialog() {
    final colorScheme = ColorScheme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF2F4F8)
            : null,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              t.home.titles.appName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              t.settings.aboutDialog.version(version: appVersion),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t.settings.aboutDialog.copyright(
                year: '${DateTime.now().year}',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: t.home.titles.appName,
              applicationVersion: appVersion,
            ),
            child: Text(t.settings.aboutDialog.licenses),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(t.common.done),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
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
        // About
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 4,
            horizontal: 16,
          ),
          leading: const UniIcon(Icons.info_outline_rounded, size: 26),
          title: Text(
            t.settings.aboutApp,
            style: const TextStyle(fontSize: 18),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showAboutDialog,
        ),
        // Version tag
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
            child: Text(
              t.settings.aboutDialog.version(version: appVersion),
              style: TextStyle(
                fontSize: 12,
                color: ColorScheme.of(context).onSurface.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
          ),
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
