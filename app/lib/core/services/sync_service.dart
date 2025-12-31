import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:vitalgate/core/services/auth_service.dart';
import 'package:vitalgate/core/services/notification_service.dart';

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
      await syncService.performSync();
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
  static const MethodChannel _channel = MethodChannel('com.bamscorp.vitalgate/health_connect');

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

  // Map permission IDs (snake_case) to Health Connect record types (PascalCase)
  // This matches HCGateway's API format
  static const Map<String, String> _permissionToRecordType = {
    'heart_rate': 'HeartRate',
    'heart_rate_variability': 'HeartRateVariabilityRmssd',
    'resting_heart_rate': 'RestingHeartRate',
    'blood_pressure': 'BloodPressure',
    'blood_oxygen': 'OxygenSaturation',
    'respiratory_rate': 'RespiratoryRate',
    'blood_glucose': 'BloodGlucose',
    'body_temperature': 'BodyTemperature',
    'basal_body_temperature': 'BasalBodyTemperature',
    'vo2_max': 'Vo2Max',
    'steps': 'Steps',
    'distance': 'Distance',
    'active_calories': 'ActiveCaloriesBurned',
    'total_calories': 'TotalCaloriesBurned',
    'floors_climbed': 'FloorsClimbed',
    'elevation_gained': 'ElevationGained',
    'speed': 'Speed',
    'power': 'Power',
    'exercise': 'ExerciseSession',
    'wheelchair_pushes': 'WheelchairPushes',
    'planned_exercise': 'PlannedExerciseSession',
    'weight': 'Weight',
    'height': 'Height',
    'body_fat': 'BodyFat',
    'body_water_mass': 'BodyWaterMass',
    'bone_mass': 'BoneMass',
    'lean_body_mass': 'LeanBodyMass',
    'basal_metabolic_rate': 'BasalMetabolicRate',
    'skin_temperature': 'SkinTemperature',
    'sleep': 'SleepSession',
    'hydration': 'Hydration',
    'nutrition': 'Nutrition',
    'menstruation_flow': 'MenstruationFlow',
    'menstruation_period': 'MenstruationPeriod',
    'cervical_mucus': 'CervicalMucus',
    'ovulation_test': 'OvulationTest',
    'sexual_activity': 'SexualActivity',
    'intermenstrual_bleeding': 'IntermenstrualBleeding',
  };

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
  Future<SyncResult> performSync({
    DateTime? customStartTime,
    DateTime? customEndTime,
    SyncProgressCallback? onProgress,
    bool showNotifications = true,
  }) async {
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

      // Filter valid permissions (exclude background_read and unmapped ones)
      final validPermissions = permissions.where((p) {
        final id = p['id'] as String;
        return id != 'background_read' && _permissionToRecordType.containsKey(id);
      }).toList();

      final totalTypes = validPermissions.length;

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
        final permissionId = permission['id'] as String;
        final recordType = _permissionToRecordType[permissionId]!;
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
          final healthData = await _getHealthDataForPermission(
            permissionId,
            startTime,
            endTime,
          );

          if (healthData.isNotEmpty) {
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
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'data': data}),
      );

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
