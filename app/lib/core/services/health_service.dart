import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  // Singleton
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  final Health _health = Health();

  // Native Method Channel for Health Connect
  static const MethodChannel _channel = MethodChannel('com.bamscorp.vitalgate/health_connect');

  HealthService._internal() {
    _health.configure();
  }

  /// Android Health Connect supported data types (Flutter health package)
  /// Used only for reading data after permissions are granted natively
  static const List<HealthDataType> _dataTypes = [
    // Activity
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.STEPS,
    HealthDataType.SPEED,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.TOTAL_CALORIES_BURNED,
    HealthDataType.WORKOUT,

    // Body Measurements
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_WATER_MASS,
    HealthDataType.HEIGHT,
    HealthDataType.LEAN_BODY_MASS,
    HealthDataType.WEIGHT,

    // Cycle Tracking
    HealthDataType.MENSTRUATION_FLOW,

    // Nutrition
    HealthDataType.WATER,
    HealthDataType.NUTRITION,

    // Sleep
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_AWAKE_IN_BED,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_OUT_OF_BED,
    HealthDataType.SLEEP_UNKNOWN,

    // Vitals
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.HEART_RATE,
    HealthDataType.HEART_RATE_VARIABILITY_RMSSD,
    HealthDataType.RESTING_HEART_RATE,
  ];

  /// Check Health Connect availability via native code
  Future<String> checkHealthConnectAvailability() async {
    try {
      final result = await _channel.invokeMethod<String>('checkAvailability');
      return result ?? 'unknown';
    } catch (e) {
      print('Error checking Health Connect availability: $e');
      return 'error';
    }
  }

  /// Request ALL Health Connect Permissions via native code
  /// This includes VO2 Max, Power, Elevation, and other types not supported by Flutter health package
  Future<Map<String, dynamic>> requestAllPermissionsNative() async {
    try {
      // 1. Request Location first
      await Permission.location.request();

      // 2. Check Health Connect availability
      final availability = await checkHealthConnectAvailability();
      if (availability != 'available') {
        return {
          'success': false,
          'message': 'Health Connect not available. Status: $availability',
        };
      }

      // 3. Request ALL Health Connect permissions via native Android code
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('requestAllPermissions');

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }

      return {
        'success': false,
        'message': 'No response from native code',
      };
    } catch (e) {
      print('Error requesting permissions: $e');
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  /// Check if ALL permissions are granted via native code
  Future<Map<String, dynamic>> checkAllPermissionsNative() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkPermissions');

      if (result != null) {
        return Map<String, dynamic>.from(result);
      }

      return {
        'granted': false,
        'count': 0,
      };
    } catch (e) {
      print('Error checking permissions: $e');
      return {
        'granted': false,
        'count': 0,
        'error': e.toString(),
      };
    }
  }

  /// Legacy: Request Permissions using Flutter health package (limited types)
  Future<bool> requestPermissions() async {
    // 1. Request Location
    await Permission.location.request();

    // 2. Check Health Connect availability
    final status = await _health.getHealthConnectSdkStatus();
    if (status != HealthConnectSdkStatus.sdkAvailable) {
      print('Health Connect SDK not available. Status: $status');
      return false;
    }

    // 3. Request Health Connect permissions
    try {
      final bool requested = await _health.requestAuthorization(
        _dataTypes,
        permissions: _dataTypes.map((e) => HealthDataAccess.READ).toList(),
      );
      return requested;
    } catch (e) {
      print('Health Permission Error: $e');
      return false;
    }
  }

  /// Legacy: Check if specific permissions are granted (Flutter health package)
  Future<bool?> hasPermissions() async {
    try {
      return await _health.hasPermissions(
        _dataTypes,
        permissions: _dataTypes.map((e) => HealthDataAccess.READ).toList(),
      );
    } catch (e) {
      print('Error checking permissions: $e');
      return null;
    }
  }

  /// Get detailed list of all permissions with their status
  Future<List<Map<String, dynamic>>> getPermissionsList() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getPermissionsList');

      if (result != null && result['success'] == true) {
        final permissions = result['permissions'] as List<dynamic>;
        return permissions.map((p) => Map<String, dynamic>.from(p as Map)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting permissions list: $e');
      return [];
    }
  }
}
