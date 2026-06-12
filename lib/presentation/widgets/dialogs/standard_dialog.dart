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
    customHeader: kIsWeb
        ? CircleAvatar(
            radius: 32,
            backgroundColor: headerColor.withOpacity(0.12),
            child: Icon(headerIcon, size: 36, color: headerColor),
          )
        : null,
    animType: AnimType.bottomSlide,
    dialogBackgroundColor: theme.colorScheme.surface,
    title: title,
    desc: content,
    body: customContent,
    dismissOnTouchOutside: barrierDismissible,
    btnCancelText: secondaryButtonText,
    btnCancelColor: isDark ? Colors.grey[800] : Colors.grey[300],
    btnCancelOnPress: secondaryButtonText != null
        ? () {
            if (onSecondaryPressed != null) onSecondaryPressed();
            if (!completer.isCompleted) completer.complete(null);
          }
        : null,
    btnOkText: primaryButtonText,
    btnOkColor: isDestructive ? Colors.red : theme.colorScheme.primary,
    btnOkOnPress: primaryButtonText != null
        ? () {
            if (onPrimaryPressed != null) onPrimaryPressed();
            if (!completer.isCompleted) completer.complete(true as T?);
          }
        : null,
    onDismissCallback: (type) {
      if (!completer.isCompleted) completer.complete(null);
    },
  ).show();

  return completer.future;
}

