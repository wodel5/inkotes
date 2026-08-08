import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:inkotes/components/theming/adaptive_switch.dart';
import 'package:inkotes/components/theming/uni_icon.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/i18n/strings.g.dart';

/// 自动检查更新设置项：图标 + 标题 + 更新来源切换（GitHub/Gitee）+ 开关。
/// 开关关闭时，更新来源切换按钮禁用。
class UpdateCheckSettings extends StatefulWidget {
  const UpdateCheckSettings({super.key});

  @override
  State<UpdateCheckSettings> createState() => _UpdateCheckSettingsState();
}

class _UpdateCheckSettingsState extends State<UpdateCheckSettings> {
  @override
  void initState() {
    stows.updateSource.addListener(onChanged);
    stows.autoCheckForUpdates.addListener(onChanged);
    super.initState();
  }

  void onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final autoCheck = stows.autoCheckForUpdates.value;
    final source = stows.updateSource.value;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      leading: const UniIcon(FontAwesomeIcons.arrowsRotate, size: 26),
      title: Text(
        t.settings.autoCheckForUpdates,
        style: const TextStyle(fontSize: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ToggleButtons(
            borderRadius: const BorderRadius.all(Radius.circular(1000)),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 40),
            onPressed: autoCheck
                ? (int index) {
                    stows.updateSource.value = UpdateSource.values[index];
                  }
                : null,
            isSelected: [
              for (final option in UpdateSource.values) option == source,
            ],
            children: const [
              Text('GitHub'),
              Text('Gitee'),
            ],
          ),
          const SizedBox(width: 8),
          AdaptiveSwitch(
            value: autoCheck,
            onChanged: (bool value) {
              stows.autoCheckForUpdates.value = value;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    stows.updateSource.removeListener(onChanged);
    stows.autoCheckForUpdates.removeListener(onChanged);
    super.dispose();
  }
}
