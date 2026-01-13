import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:vitalgate/core/services/auth_service.dart';
import 'package:vitalgate/core/services/notification_service.dart';
import 'package:vitalgate/core/services/sync_history_service.dart';

/// Sync state enum for UI updates
enum SyncState {
  idle,
  requestingPermissions,
  submittingFcm,
  uploadingArchive,
  syncingData,
  completed,
  error,
}

/// Sync progress callback type
typedef SyncProgressCallback = void Function(SyncState state, String message, int current, int total);

/// Background sync task name
const String backgroundSyncTask = 'com.bamscorp.vitalgate.backgroundSync';

/// Callback dispatcher for WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundSyncTask) {
      final syncService = SyncService();
      await syncService.performSync(isBackgroundSync: true);
    }
    return Future.value(true);
  });
}

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final SyncHistoryService _historyService = SyncHistoryService();
  static const MethodChannel _channel = MethodChannel('com.bamscorp.vitalgate/health_connect');

  // Cancellation flag
  bool _isCancelled = false;

  /// Request sync cancellation
  void cancelSync() {
    _isCancelled = true;
  }

  /// Check if sync is cancelled
  bool get isCancelled => _isCancelled;

  // Storage keys
  static const String _keySyncInterval = 'sync_interval';
  static const String _keyHistoryRange = 'history_range';
  static const String _keyWantUploadOldHistory = 'want_upload_old_history';
  static const String _keyLastSync = 'last_sync';

  // Sync interval options (in hours)
  static const Map<String, int> syncIntervalHours = {
    'Every 1 hour': 1,
    'Every 2 hours': 2,
    'Every 6 hours': 6,
    'Every 12 hours': 12,
    'Once a day': 24,
  };

  // History range options (in days)
  static const Map<String, int> historyRangeDays = {
    '1 day': 1,
    '2 days': 2,
    '1 week': 7,
    '15 days': 15,
    '21 days': 21,
    '30 days': 30,
  };

  // Permission IDs that should be synced (Body Measurements category)
  static const List<String> _allowedPermissionIds = [
    'basal_metabolic_rate',
    'body_fat',
    'body_water_mass',
    'bone_mass',
    'height',
    'lean_body_mass',
    'weight',
  ];

  // Large data types that should be synced one record at a time (like HCGateway)
  static const List<String> _largeDataTypes = ['SleepSession', 'Speed', 'HeartRate'];

  /// Initialize WorkManager for background sync
  Future<void> initializeBackgroundSync() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Schedule background sync based on saved interval
  Future<void> scheduleBackgroundSync() async {
    final interval = await getSyncInterval();
    final hours = syncIntervalHours[interval] ?? 1;

    // Cancel existing tasks
    await Workmanager().cancelByUniqueName(backgroundSyncTask);

    // Schedule new periodic task
    await Workmanager().registerPeriodicTask(
      backgroundSyncTask,
      backgroundSyncTask,
      frequency: Duration(hours: hours),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
    );
  }

  /// Cancel background sync
  Future<void> cancelBackgroundSync() async {
    await Workmanager().cancelByUniqueName(backgroundSyncTask);
  }

  // Settings getters/setters
  Future<String> getSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySyncInterval) ?? 'Every 1 hour';
  }

  Future<void> setSyncInterval(String interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySyncInterval, interval);
    // Reschedule background sync with new interval
    await scheduleBackgroundSync();
  }

  Future<String> getHistoryRange() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyHistoryRange) ?? '7 days';
  }

  Future<void> setHistoryRange(String range) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHistoryRange, range);
  }

  Future<bool> getWantUploadOldHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyWantUploadOldHistory) ?? false;
  }

  Future<void> setWantUploadOldHistory(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWantUploadOldHistory, value);
  }

  Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyLastSync);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  Future<void> setLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyLastSync, time.millisecondsSinceEpoch);
  }

  /// Get list of granted permissions from Health Connect
  Future<List<Map<String, dynamic>>> getGrantedPermissions() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPermissionsList');

      if (result != null && result['success'] == true) {
        final permissions = result['permissions'] as List<dynamic>;
        return permissions
            .map((p) => Map<String, dynamic>.from(p as Map))
            .where((p) => p['granted'] == true)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting permissions list: $e');
      return [];
    }
  }

  /// Perform sync - upload all health data to API (HCGateway compatible)
  /// [onProgress] callback for UI updates with current state, message, and progress
  /// [showNotifications] whether to show system notifications (default: true)
  /// [isBackgroundSync] whether this is a background sync (for history logging)
  Future<SyncResult> performSync({
    DateTime? customStartTime,
    DateTime? customEndTime,
    SyncProgressCallback? onProgress,
    bool showNotifications = true,
    bool isBackgroundSync = false,
  }) async {
    // Reset cancellation flag at start
    _isCancelled = false;

    try {
      // Initialize notification service
      if (showNotifications) {
        await _notificationService.initialize();
        await _notificationService.showSyncStarted();
      }

      final baseUrl = await _authService.getBaseUrl();
      final accessToken = await _authService.getAccessToken();

      if (baseUrl == null || accessToken == null) {
        if (showNotifications) {
          await _notificationService.cancelSyncNotification();
        }
        onProgress?.call(SyncState.error, 'Not authenticated', 0, 0);
        return SyncResult(
          success: false,
          message: 'Not authenticated',
          uploadedCount: 0,
          failedCount: 0,
        );
      }

      // Get granted permissions
      onProgress?.call(SyncState.syncingData, 'Getting permissions...', 0, 0);
      final permissions = await getGrantedPermissions();
      print('DEBUG: Got ${permissions.length} granted permissions');
      for (final p in permissions) {
        print('DEBUG: Permission: ${p['id']}, recordType: ${p['recordType']}, granted: ${p['granted']}');
      }

      if (permissions.isEmpty) {
        if (showNotifications) {
          await _notificationService.cancelSyncNotification();
        }
        onProgress?.call(SyncState.error, 'No permissions granted', 0, 0);
        return SyncResult(
          success: false,
          message: 'No permissions granted',
          uploadedCount: 0,
          failedCount: 0,
        );
      }

      // Filter valid permissions (only allowed types that are granted and have recordType)
      final validPermissions = permissions.where((p) {
        final id = p['id'] as String;
        final recordType = p['recordType'] as String?;
        final isAllowed = _allowedPermissionIds.contains(id);
        print('DEBUG: Checking $id - recordType: $recordType, isAllowed: $isAllowed');
        return id != 'background_read' &&
               recordType != null &&
               isAllowed;
      }).toList();

      print('DEBUG: Valid permissions after filter: ${validPermissions.length}');

      final totalTypes = validPermissions.length;

      if (totalTypes == 0) {
        if (showNotifications) {
          await _notificationService.cancelSyncNotification();
        }
        onProgress?.call(SyncState.error, 'No body measurement permissions', 0, 0);
        return SyncResult(
          success: false,
          message: 'No body measurement permissions granted',
          uploadedCount: 0,
          failedCount: 0,
        );
      }

      // Determine time range
      final DateTime endTime = customEndTime ?? DateTime.now();
      DateTime startTime;

      if (customStartTime != null) {
        startTime = customStartTime;
      } else {
        final historyRange = await getHistoryRange();
        final days = historyRangeDays[historyRange] ?? 7;
        startTime = endTime.subtract(Duration(days: days));
      }

      // Save last sync time
      if (customStartTime == null) {
        await setLastSync(DateTime.now());
      }

      int uploadedCount = 0;
      int failedCount = 0;
      int currentTypeIndex = 0;
      final errors = <String>[];

      // Upload data for each granted permission
      for (final permission in validPermissions) {
        // Check for cancellation
        if (_isCancelled) {
          if (showNotifications) {
            await _notificationService.cancelSyncNotification();
          }
          return SyncResult(
            success: false,
            message: 'Sync cancelled',
            uploadedCount: uploadedCount,
            failedCount: failedCount,
          );
        }

        final permissionId = permission['id'] as String;
        final recordType = permission['recordType'] as String;
        currentTypeIndex++;

        // Update progress
        onProgress?.call(
          SyncState.syncingData,
          'Syncing $recordType...',
          currentTypeIndex,
          totalTypes,
        );

        if (showNotifications) {
          await _notificationService.showSyncProgress(
            current: currentTypeIndex,
            total: totalTypes,
            recordType: recordType,
          );
        }

        try {
          // Get health data for this permission type
          print('DEBUG: Getting health data for $permissionId from $startTime to $endTime');
          final healthData = await _getHealthDataForPermission(
            permissionId,
            startTime,
            endTime,
          );
          print('DEBUG: Got ${healthData.length} records for $permissionId');

          if (healthData.isNotEmpty) {
            print('DEBUG: Uploading ${healthData.length} $recordType records to $baseUrl/api/v1/health/$recordType');
            // For large data types, sync one at a time
            if (_largeDataTypes.contains(recordType)) {
              for (int i = 0; i < healthData.length; i++) {
                final record = healthData[i];
                final uploaded = await _uploadHealthData(
                  baseUrl: baseUrl,
                  accessToken: accessToken,
                  recordType: recordType,
                  data: [record],
                );
                if (uploaded) {
                  uploadedCount++;
                } else {
                  failedCount++;
                }

                // Update notification for large data types
                if (showNotifications && healthData.length > 1) {
                  await _notificationService.showSyncProgress(
                    current: currentTypeIndex,
                    total: totalTypes,
                    recordType: '$recordType (${i + 1}/${healthData.length})',
                  );
                }

                await Future.delayed(const Duration(milliseconds: 100));
              }
            } else {
              // For other types, upload all records at once
              final uploaded = await _uploadHealthData(
                baseUrl: baseUrl,
                accessToken: accessToken,
                recordType: recordType,
                data: healthData,
              );

              if (uploaded) {
                uploadedCount += healthData.length;
              } else {
                failedCount += healthData.length;
                errors.add(recordType);
              }
            }
          }
        } catch (e) {
          failedCount++;
          errors.add('$recordType: $e');
        }
      }

      // Show completion notification
      if (showNotifications) {
        await _notificationService.showSyncCompleted(
          uploadedCount: uploadedCount,
          failedCount: failedCount,
        );
      }

      final result = SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'Successfully synced $uploadedCount records'
            : 'Synced $uploadedCount, failed $failedCount',
        uploadedCount: uploadedCount,
        failedCount: failedCount,
        errors: errors,
      );

      // Log to sync history
      await _historyService.logSync(
        successCount: uploadedCount,
        failedCount: failedCount,
        errors: errors,
        isBackgroundSync: isBackgroundSync,
      );

      onProgress?.call(
        failedCount == 0 ? SyncState.completed : SyncState.error,
        result.message,
        totalTypes,
        totalTypes,
      );

      return result;
    } catch (e) {
      if (showNotifications) {
        await _notificationService.cancelSyncNotification();
      }

      // Log error to sync history
      await _historyService.logSync(
        successCount: 0,
        failedCount: 1,
        errors: ['Sync error: $e'],
        isBackgroundSync: isBackgroundSync,
      );

      onProgress?.call(SyncState.error, 'Sync error: $e', 0, 0);
      return SyncResult(
        success: false,
        message: 'Sync error: $e',
        uploadedCount: 0,
        failedCount: 0,
      );
    }
  }

  /// Get health data for a specific permission type from native
  Future<List<Map<String, dynamic>>> _getHealthDataForPermission(
    String permissionId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getHealthData',
        {
          'type': permissionId,
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );

      if (result != null && result['success'] == true) {
        final data = result['data'] as List<dynamic>? ?? [];
        return data.map((d) => Map<String, dynamic>.from(d as Map)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting health data for $permissionId: $e');
      return [];
    }
  }

  /// TEST: Read historical data for testing READ_HEALTH_DATA_HISTORY permission
  Future<String> testReadHistoricalData({
    required String permissionId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      // First check if permission is granted
      final permResult = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPermissionsList');
      String permStatus = 'unknown';
      if (permResult != null && permResult['success'] == true) {
        final permissions = permResult['permissions'] as List<dynamic>? ?? [];
        final weightPerm = permissions.firstWhere(
          (p) => p['id'] == permissionId,
          orElse: () => null,
        );
        if (weightPerm != null) {
          permStatus = weightPerm['granted'] == true ? 'GRANTED' : 'NOT GRANTED';
        } else {
          permStatus = 'NOT FOUND in list';
        }
      }

      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getHealthData',
        {
          'type': permissionId,
          'startTime': startTime.millisecondsSinceEpoch,
          'endTime': endTime.millisecondsSinceEpoch,
        },
      );

      final dateStr = '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}';

      if (result != null) {
        final success = result['success'];
        final error = result['error'];
        final data = result['data'] as List<dynamic>? ?? [];

        if (success == true) {
          if (data.isEmpty) {
            return 'Permission: $permStatus\nDate: $dateStr\nResult: No data found (empty list returned)';
          }
          return 'Permission: $permStatus\nDate: $dateStr\nFound ${data.length} record(s):\n${data.first}';
        } else {
          return 'Permission: $permStatus\nDate: $dateStr\nError: ${error ?? 'Unknown error'}';
        }
      }
      return 'Permission: $permStatus\nNo response from native code';
    } catch (e) {
      return 'Exception: $e';
    }
  }

  /// Upload health data to API (HCGateway compatible format)
  /// Endpoint: /api/v1/health/{RecordType}
  Future<bool> _uploadHealthData({
    required String baseUrl,
    required String accessToken,
    required String recordType,
    required List<Map<String, dynamic>> data,
  }) async {
    try {
      // Use HCGateway's API format: /api/v1/health/{RecordType}
      final uri = Uri.parse('$baseUrl/api/v1/health/$recordType');
      print('DEBUG: POST $uri with ${data.length} records');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'data': data}),
      );
      print('DEBUG: Response ${response.statusCode}: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }

      // Try refresh token if 401
      if (response.statusCode == 401) {
        final newToken = await _authService.refreshToken();
        if (newToken != null) {
          final retryResponse = await http.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
            body: jsonEncode({'data': data}),
          );
          return retryResponse.statusCode >= 200 && retryResponse.statusCode < 300;
        }
      }

      return false;
    } catch (e) {
      print('Error uploading health data for $recordType: $e');
      return false;
    }
  }

  /// Upload archive file to API
  Future<bool> uploadArchiveFile({
    required String filePath,
  }) async {
    try {
      final baseUrl = await _authService.getBaseUrl();
      final accessToken = await _authService.getAccessToken();

      if (baseUrl == null || accessToken == null) {
        return false;
      }

      final uri = Uri.parse('$baseUrl/api/v1/health/archive');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(await http.MultipartFile.fromPath('archive', filePath));

      final response = await request.send();
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Error uploading archive: $e');
      return false;
    }
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int uploadedCount;
  final int failedCount;
  final List<String>? errors;

  SyncResult({
    required this.success,
    required this.message,
    required this.uploadedCount,
    required this.failedCount,
    this.errors,
  });
}
