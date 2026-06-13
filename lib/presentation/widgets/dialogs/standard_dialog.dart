import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

Future<T?> showStandardDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  Widget? customContent,
  String? primaryButtonText,
  VoidCallback? onPrimaryPressed,
  String? secondaryButtonText,
  VoidCallback? onSecondaryPressed,
  bool isDestructive = false,
  IconData? icon,
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final completer = Completer<T?>();

  // Trên web, awesome_dialog không render được icon từ asset Flare/Rive,
  // nên dùng customHeader với Material Icon thay thế.
  final headerIcon = icon ??
      (isDestructive ? Icons.error_rounded : Icons.info_rounded);
  final headerColor = isDestructive ? Colors.red : theme.colorScheme.primary;

  AwesomeDialog(
    context: context,
    width: 520,
    dialogType: kIsWeb ? DialogType.noHeader : (isDestructive ? DialogType.error : DialogType.info),
    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
    borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5), width: 1),
    customHeader: kIsWeb
        ? CircleAvatar(
            radius: 32,
            backgroundColor: headerColor.withValues(alpha: 0.12),
            child: Icon(headerIcon, size: 36, color: headerColor),
          )
        : null,
    animType: AnimType.bottomSlide,
    dialogBackgroundColor: theme.colorScheme.surface,
    title: title,
    desc: content,
    body: customContent,
    dismissOnTouchOutside: barrierDismissible,
    btnCancel: secondaryButtonText != null
        ? SizedBox(
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5), width: 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                if (onSecondaryPressed != null) onSecondaryPressed();
                if (!completer.isCompleted) completer.complete(null);
              },
              child: Text(
                secondaryButtonText,
                style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[800], fontWeight: FontWeight.w600),
              ),
            ),
          )
        : null,
    btnOk: primaryButtonText != null
        ? SizedBox(
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : theme.colorScheme.primary,
                foregroundColor: isDestructive ? Colors.white : theme.colorScheme.onPrimary,
                side: BorderSide(
                  color: isDestructive ? Colors.red[700]! : theme.colorScheme.primary.withValues(alpha: 0.8),
                  width: 1,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              ),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                if (onPrimaryPressed != null) onPrimaryPressed();
                if (!completer.isCompleted) completer.complete(true as T?);
              },
              child: Text(
                primaryButtonText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
        : null,
    onDismissCallback: (type) {
      if (!completer.isCompleted) completer.complete(null);
    },
  ).show();

  return completer.future;
}

