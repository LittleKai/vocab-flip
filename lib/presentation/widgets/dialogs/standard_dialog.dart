import 'dart:async';
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

  AwesomeDialog(
    context: context,
    width: 450, // Giới hạn chiều rộng tối đa trên Web/Desktop
    dialogType: isDestructive ? DialogType.error : DialogType.info,
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

