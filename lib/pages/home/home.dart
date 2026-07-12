import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foledge/components/home/sentry_consent_dialog.dart';
import 'package:foledge/components/navbar/responsive_navbar.dart';
import 'package:foledge/pages/home/browse.dart';
import 'package:foledge/pages/home/recent_notes.dart';
import 'package:foledge/pages/home/settings.dart';
import 'package:foledge/pages/home/whiteboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.subpage, required this.path});

  final String subpage;
  final String? path;

  @override
  State<HomePage> createState() => _HomePageState();

  static const recentSubpage = 'recent';
  static const browseSubpage = 'browse';
  static const whiteboardSubpage = 'whiteboard';
  static const settingsSubpage = 'settings';
  static const List<String> subpages = [
    recentSubpage,
    browseSubpage,
    whiteboardSubpage,
    settingsSubpage,
  ];
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _showDialogs();
  }

  void _showDialogs() async {
    await null; // initState must be completed before using context
    if (!mounted) return;
    SentryConsentDialog.showIfNeeded(context);
  }

  Widget get body {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey(widget.subpage),
        child: switch (widget.subpage) {
          HomePage.browseSubpage => BrowsePage(path: widget.path),
          HomePage.whiteboardSubpage => const Whiteboard(),
          HomePage.settingsSubpage => const SettingsPage(),
          _ => const RecentPage(),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavbar(
      selectedIndex: HomePage.subpages.indexOf(widget.subpage),
      body: body,
    );
  }

  @override
  @override
  void dispose() {
    super.dispose();
  }
}
