import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static const int syncNotificationId = 1001;
  static const String syncChannelId = 'sync_progress';
  static const String syncChannelName = 'Sync Progress';

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(initSettings);

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      syncChannelId,
      syncChannelName,
      description: 'Shows sync progress',
      importance: Importance.low,
      showBadge: false,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _isInitialized = true;
  }

  /// Show sync progress notification
  Future<void> showSyncProgress({
    required int current,
    required int total,
    required String recordType,
  }) async {
    await initialize();

    final androidDetails = AndroidNotificationDetails(
      syncChannelId,
      syncChannelName,
      channelDescription: 'Shows sync progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: total,
      progress: current,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    await _notifications.show(
      syncNotificationId,
      'Syncing Health Data',
      'Uploading $recordType... [$current/$total]',
      NotificationDetails(android: androidDetails),
    );
  }

  /// Show sync starting notification
  Future<void> showSyncStarted() async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      syncChannelId,
      syncChannelName,
      channelDescription: 'Shows sync progress',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
    );

    await _notifications.show(
      syncNotificationId,
      'VitalGate Sync',
      'Starting health data sync...',
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Show sync completed notification
  Future<void> showSyncCompleted({
    required int uploadedCount,
    required int failedCount,
  }) async {
    await initialize();

    final isSuccess = failedCount == 0;
    final message = isSuccess
        ? 'Successfully synced $uploadedCount records'
        : 'Synced $uploadedCount, failed $failedCount';

    const androidDetails = AndroidNotificationDetails(
      syncChannelId,
      syncChannelName,
      channelDescription: 'Shows sync progress',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      ongoing: false,
      autoCancel: true,
    );

    await _notifications.show(
      syncNotificationId,
      isSuccess ? 'Sync Complete' : 'Sync Finished with Errors',
      message,
      const NotificationDetails(android: androidDetails),
    );
  }

  /// Cancel sync notification
  Future<void> cancelSyncNotification() async {
    await _notifications.cancel(syncNotificationId);
  }
}
