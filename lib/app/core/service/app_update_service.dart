import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/remote/remote_data_source.dart';
import '../../data/model/app_version_response.dart';
import 'launch_prompt_gate.dart';

/// Checks the backend for a newer app version and shows a non-blocking
/// bottom-sheet (or a forced dialog) when an update is available.
///
/// Call [checkAndNotify] once after the app boots; it is entirely
/// fire-and-forget — errors are swallowed silently.
class AppUpdateService {
  const AppUpdateService(this._remote);

  final RemoteDataSource _remote;

  static const _playStoreUrl =
      'https://play.google.com/store/apps/details?id=tz.co.artbel.hostbora';
  static const _appStoreUrl =
      'https://apps.apple.com/app/id6737561267';

  Future<void> checkAndNotify() async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      final info = await PackageInfo.fromPlatform();
      final current = info.version.trim();

      final latest = await _remote.checkAppVersion(platform);
      if (latest.latestVersion.isEmpty) return;

      final hasUpdate = _isNewer(latest.latestVersion, current);
      final forceUpdate =
          latest.forceUpdate ||
          (latest.minVersion.isNotEmpty &&
              _isNewer(latest.minVersion, current));

      if (!hasUpdate && !forceUpdate) return;

      if (forceUpdate) {
        // Critical — always show, does not consume the soft-prompt slot.
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        _showForceUpdateDialog(latest);
        return;
      }

      // Soft update yields to lease/review: wait until after their window, then
      // only show if no other soft launch prompt claimed the slot.
      await Future<void>.delayed(const Duration(milliseconds: 3500));
      if (Get.isRegistered<LaunchPromptGate>() &&
          !Get.find<LaunchPromptGate>().tryClaimSoftPrompt()) {
        return;
      }
      _showUpdateSheet(latest, current);
    } catch (_) {
      // Version check is best-effort; never crash the app.
    }
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  void _showUpdateSheet(AppVersionResponse info, String currentVersion) {
    Get.bottomSheet(
      _UpdateSheet(
        info: info,
        currentVersion: currentVersion,
        onUpdate: () {
          Get.back();
          _launchStore(info.updateUrl);
        },
        onDismiss: Get.back,
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showForceUpdateDialog(AppVersionResponse info) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Update Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This version of Host Bora is no longer supported. '
                'Please update to continue.',
              ),
              if (info.releaseNotes != null) ...[
                const SizedBox(height: 12),
                Text(
                  info.releaseNotes!,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => _launchStore(info.updateUrl),
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _launchStore(String? customUrl) async {
    final raw = customUrl?.isNotEmpty == true
        ? customUrl!
        : (Platform.isIOS ? _appStoreUrl : _playStoreUrl);
    final uri = Uri.parse(raw);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ── Version comparison ────────────────────────────────────────────────────

  /// Returns true when [candidate] is strictly newer than [installed].
  static bool _isNewer(String candidate, String installed) {
    final c = _parse(candidate);
    final i = _parse(installed);
    for (var idx = 0; idx < 3; idx++) {
      if (c[idx] > i[idx]) return true;
      if (c[idx] < i[idx]) return false;
    }
    return false;
  }

  static List<int> _parse(String version) {
    final parts = version.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}

// ── Bottom-sheet widget ──────────────────────────────────────────────────────

class _UpdateSheet extends StatelessWidget {
  const _UpdateSheet({
    required this.info,
    required this.currentVersion,
    required this.onUpdate,
    required this.onDismiss,
  });

  final AppVersionResponse info;
  final String currentVersion;
  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Icon + title row
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: cs.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'New Update Available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v$currentVersion  →  v${info.latestVersion}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Release notes
          if (info.releaseNotes?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                info.releaseNotes!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Later'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onUpdate,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Update Now'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
