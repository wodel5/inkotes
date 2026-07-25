import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foledge/components/theming/adaptive_alert_dialog.dart';
import 'package:foledge/components/theming/adaptive_text_field.dart';
import 'package:foledge/data/file_manager/file_manager.dart';
import 'package:foledge/i18n/strings.g.dart';
import 'package:foledge/pages/editor/editor.dart';

/// Dialog for renaming a note file.
class RenameNoteDialog extends StatefulWidget {
  const RenameNoteDialog({
    super.key,
    required this.existingPath,
    required this.unselectNotes,
  });

  final String existingPath;
  final void Function() unselectNotes;

  @override
  State<RenameNoteDialog> createState() => _RenameNoteDialogState();
}

class _RenameNoteDialogState extends State<RenameNoteDialog> {
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
