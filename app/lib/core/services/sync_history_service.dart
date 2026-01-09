import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for a single sync history entry
class SyncHistoryEntry {
  final String id;
  final DateTime timestamp;
  final int successCount;
  final int failedCount;
  final List<String> errors;
  final bool isBackgroundSync;

  SyncHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.successCount,
    required this.failedCount,
    this.errors = const [],
    this.isBackgroundSync = false,
  });

  /// Check if sync was fully successful (no failures)
  bool get isSuccess => failedCount == 0;

  /// Check if sync had some failures but also some success
  bool get hasWarnings => failedCount > 0 && successCount > 0;

  /// Total records processed
  int get totalRecords => successCount + failedCount;

  factory SyncHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SyncHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      successCount: json['successCount'] as int,
      failedCount: json['failedCount'] as int,
      errors: (json['errors'] as List<dynamic>?)?.cast<String>() ?? [],
      isBackgroundSync: json['isBackgroundSync'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'successCount': successCount,
      'failedCount': failedCount,
      'errors': errors,
      'isBackgroundSync': isBackgroundSync,
    };
  }
}

/// Service for managing sync history logs in persistent storage
class SyncHistoryService {
  static final SyncHistoryService _instance = SyncHistoryService._internal();
  factory SyncHistoryService() => _instance;
  SyncHistoryService._internal();

  static const String _storageKey = 'sync_history_logs';
  static const int _maxEntries = 100; // Keep last 100 sync entries

  /// Get all sync history entries, sorted by timestamp (newest first)
  Future<List<SyncHistoryEntry>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final entries = jsonList
          .map((json) => SyncHistoryEntry.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by timestamp descending (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return entries;
    } catch (e) {
      print('Error loading sync history: $e');
      return [];
    }
  }

  /// Add a new sync history entry
  Future<void> addEntry(SyncHistoryEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = await getHistory();

      // Add new entry at the beginning
      entries.insert(0, entry);

      // Keep only the last N entries
      final trimmedEntries = entries.take(_maxEntries).toList();

      // Save to storage
      final jsonList = trimmedEntries.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving sync history: $e');
    }
  }

  /// Log a sync result (convenience method)
  Future<void> logSync({
    required int successCount,
    required int failedCount,
    List<String>? errors,
    bool isBackgroundSync = false,
  }) async {
    final entry = SyncHistoryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      successCount: successCount,
      failedCount: failedCount,
      errors: errors ?? [],
      isBackgroundSync: isBackgroundSync,
    );

    await addEntry(entry);
  }

  /// Clear all sync history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing sync history: $e');
    }
  }

  /// Get stats for the last N days
  Future<SyncStats> getStats({int days = 7}) async {
    final entries = await getHistory();
    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    final recentEntries = entries.where((e) => e.timestamp.isAfter(cutoffDate)).toList();

    int totalSuccess = 0;
    int totalFailed = 0;

    for (final entry in recentEntries) {
      totalSuccess += entry.successCount;
      totalFailed += entry.failedCount;
    }

    final totalRecords = totalSuccess + totalFailed;
    final successRate = totalRecords > 0 ? (totalSuccess / totalRecords * 100) : 100.0;

    return SyncStats(
      totalRecords: totalRecords,
      successRate: successRate,
      syncCount: recentEntries.length,
    );
  }
}

/// Summary statistics for sync history
class SyncStats {
  final int totalRecords;
  final double successRate;
  final int syncCount;

  SyncStats({
    required this.totalRecords,
    required this.successRate,
    required this.syncCount,
  });
}
