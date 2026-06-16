import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_version.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/update_provider.dart';
import '../../providers/settings_provider.dart';
import 'update_progress_dialog.dart';
import 'standard_dialog.dart';

/// Dialog to show when an update is available
class UpdateDialog extends StatelessWidget {
  final AppVersion version;
  final bool isMandatory;

  const UpdateDialog({
    super.key,
    required this.version,
    this.isMandatory = false,
  });

  /// Show the update dialog
  static Future<void> show(
    BuildContext context, {
    required AppVersion version,
    bool isMandatory = false,
  }) {
    return showStandardDialog(
      context: context,
      title: AppLocalizations.of(context)!.updateAvailable,
      barrierDismissible: !isMandatory,
      customContent: UpdateDialog(
        version: version,
        isMandatory: isMandatory,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final locale = settings.locale;
    final releaseNotes = version.getReleaseNotes(locale);

    return PopScope(
      canPop: !isMandatory,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Version info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.currentVersion,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                context.read<UpdateProvider>().currentVersion,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward,
                            color: AppColors.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.newVersion,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                version.version,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (releaseNotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.whatsNew,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: SingleChildScrollView(
                        child: Text(
                          releaseNotes,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],

                  if (isMandatory) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.warning),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.updateRequired,
                              style: const TextStyle(color: AppColors.warning),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!isMandatory)
                        TextButton(
                          onPressed: () {
                            context.read<UpdateProvider>().skipVersion();
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.skipVersion),
                        ),
                      if (!isMandatory)
                        TextButton(
                          onPressed: () {
                            context.read<UpdateProvider>().dismissUpdate();
                            Navigator.of(context).pop();
                          },
                          child: Text(l10n.updateLater),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _startDownload(context);
                        },
                        icon: const Icon(Icons.download),
                        label: Text(l10n.downloadUpdate),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startDownload(BuildContext context) {
    if (!kIsWeb && Platform.isAndroid) {
      // On Android: open APK download URL or releases page
      final updateProvider = context.read<UpdateProvider>();
      final apkUrl = version.apkDownloadUrl;
      if (apkUrl.isNotEmpty) {
        launchUrl(Uri.parse(apkUrl), mode: LaunchMode.externalApplication);
      } else {
        updateProvider.openReleasesPage();
      }
    } else {
      // On Windows: download + extract + install
      UpdateProgressDialog.show(context);
    }
  }
}
