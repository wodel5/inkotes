import 'package:flutter/foundation.dart';
import 'package:inkotes/data/prefs.dart';
import 'package:inkotes/data/models/tool_id.dart';

abstract class Tool {
  @protected
  @visibleForTesting
  const Tool();

  /// An identifier for the tool,
  /// used to save the last-used tool in [stows.lastTool].
  ToolId get toolId;

  static const Tool textEditing = _TextEditingTool();
}

class _TextEditingTool extends Tool {
  const _TextEditingTool();

  @override
  ToolId get toolId => .textEditing;
}
