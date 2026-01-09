import 'package:flutter/services.dart';

/// Service to get app permissions dynamically from Android PackageManager
class PermissionService {
  static const _channel = MethodChannel('app/permissions');

  /// Get all declared permissions for this app and their grant status
  static Future<List<PermissionInfo>> getAppPermissions() async {
    try {
      final List<dynamic> result = await _channel.invokeMethod('getPermissions');

      return result.map((item) => PermissionInfo(
        name: item['name'] as String,
        isGranted: item['granted'] as bool,
        group: item['group'] as String?,
        description: item['description'] as String?,
        protectionLevel: item['protectionLevel'] as String?,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get permissions grouped by category
  static Future<Map<String, List<PermissionInfo>>> getGroupedPermissions() async {
    final permissions = await getAppPermissions();
    final grouped = <String, List<PermissionInfo>>{};

    for (final perm in permissions) {
      final category = perm.category;
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(perm);
    }

    // Sort categories in desired order
    final orderedCategories = [
      'Health Connect',
      'Medical Data',
      'Location',
      'Storage',
      'Notifications',
      'System',
      'Other',
    ];

    final sortedGrouped = <String, List<PermissionInfo>>{};
    for (final category in orderedCategories) {
      if (grouped.containsKey(category)) {
        sortedGrouped[category] = grouped[category]!;
      }
    }

    // Add any remaining categories
    for (final entry in grouped.entries) {
      if (!sortedGrouped.containsKey(entry.key)) {
        sortedGrouped[entry.key] = entry.value;
      }
    }

    return sortedGrouped;
  }
}

/// Permission information model
class PermissionInfo {
  final String name;
  final bool isGranted;
  final String? group;
  final String? description;
  final String? protectionLevel;

  PermissionInfo({
    required this.name,
    required this.isGranted,
    this.group,
    this.description,
    this.protectionLevel,
  });

  /// Get short display name from permission
  String get shortName {
    var displayName = name
        .replaceAll('android.permission.', '')
        .replaceAll('android.permission.health.', '');

    // Convert to readable format: READ_HEART_RATE -> Heart Rate
    displayName = displayName
        .replaceAll('READ_', '')
        .replaceAll('WRITE_', '')
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');

    return displayName;
  }

  /// Get category based on permission name
  String get category {
    if (name.contains('android.permission.health.READ_MEDICAL_DATA')) {
      return 'Medical Data';
    }
    if (name.contains('android.permission.health.')) {
      return 'Health Connect';
    }
    if (name.contains('LOCATION') || name.contains('ACCESS_FINE') || name.contains('ACCESS_COARSE')) {
      return 'Location';
    }
    if (name.contains('STORAGE') || name.contains('EXTERNAL')) {
      return 'Storage';
    }
    if (name.contains('NOTIFICATION')) {
      return 'Notifications';
    }
    if (name.contains('VIBRATE') || name.contains('INTERNET') || name.contains('FOREGROUND_SERVICE') || name.contains('SYSTEM_ALERT')) {
      return 'System';
    }
    return 'Other';
  }

  @override
  String toString() => '$shortName: ${isGranted ? "Granted" : "Denied"}';
}
