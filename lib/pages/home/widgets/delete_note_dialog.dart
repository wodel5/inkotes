import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foledge/components/theming/adaptive_alert_dialog.dart';
import 'package:foledge/data/file_manager/file_manager.dart';
import 'package:foledge/i18n/strings.g.dart';

/// Dialog for confirming deletion of one or more notes.
class DeleteNoteDialog extends StatefulWidget {
  const DeleteNoteDialog({
    super.key,
    required this.filesToDelete,
    required this.unselectNotes,
  });

  final List<String> filesToDelete;
  final void Function() unselectNotes;

  @override
  State<DeleteNoteDialog> createState() => _DeleteNoteDialogState();
}

class _DeleteNoteDialogState extends State<DeleteNoteDialog> {
  var deleteAllowed = false;

  @override
  Widget build(BuildContext context) {
    return AdaptiveAlertDialog(
      title: widget.filesToDelete.length < 5
          ? Text(
              t.home.deleteNoteDialog.deleteName(
                f: widget.filesToDelete.join(', '),
              ),
            )
          : Text(
              t.home.deleteNoteDialog.deleteNotes(
                n: widget.filesToDelete.length,
              ),
            ),
      content: CheckboxListTile.adaptive(
        value: deleteAllowed,
        onChanged: (value) => setState(() => deleteAllowed = value!),
        controlAffinity: .leading,
        title: Text(
          t.home.deleteNoteDialog.confirmDelete(n: widget.filesToDelete.length),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        CupertinoDialogAction(
          onPressed: deleteAllowed
              ? () async {
                  await Future.wait([
                    for (final String filePath in widget.filesToDelete)
                      FileManager.markAsTrashed(filePath),
                  ]);
                  if (context.mounted) Navigator.of(context).pop();
                  widget.unselectNotes();
                }
              : null,
          isDestructiveAction: true,
          child: Text(t.home.deleteNoteDialog.delete),
        ),
      ],
    );
  }
}
