import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';

class UpdateCheckResult {
  final bool updateAvailable;
  final bool mandatory;
  final String updateUrl;
  final String currentVersionLabel;
  const UpdateCheckResult({
    required this.updateAvailable,
    required this.mandatory,
    required this.updateUrl,
    required this.currentVersionLabel,
  });
}

class UpdateService {
  final ApiClient apiClient;
  UpdateService(this.apiClient);

  Future<UpdateCheckResult> check() async {
    final info = await PackageInfo.fromPlatform();
    final currentCode = int.tryParse(info.buildNumber) ?? 0;
    final config = await apiClient.getAppConfig();
    return UpdateCheckResult(
      updateAvailable: currentCode < config.latestVersionCode,
      mandatory: currentCode < config.minSupportedVersionCode,
      updateUrl: config.updateUrl,
      currentVersionLabel: 'v${info.version} (Build ${info.buildNumber})',
    );
  }

  Future<void> openUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
