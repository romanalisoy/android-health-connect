import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/services/health_service.dart';
import 'package:vitalgate/core/services/auth_service.dart';
import 'package:vitalgate/core/services/sync_service.dart';
import 'package:vitalgate/features/profile/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _syncInterval = 'Every 1 hour';
  String _historyRange = '1 week';
  bool _isSyncing = false;

  // Sync state for button text
  SyncState _syncState = SyncState.idle;
  String _syncMessage = '';
  bool _syncCancelled = false;

  // User info and weather
  UserInfo? _userInfo;
  WeatherInfo? _weatherInfo;
  bool _isLoadingUserInfo = true;
  bool _isLoadingWeather = true;

  final HealthService _healthService = HealthService();
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  // Dropdown options
  static const List<String> _syncIntervalOptions = [
    'Every 1 hour',
    'Every 2 hours',
    'Every 6 hours',
    'Every 12 hours',
    'Once a day',
  ];

  static const List<String> _historyRangeOptions = [
    '1 day',
    '2 days',
    '1 week',
    '15 days',
    '21 days',
    '30 days',
  ];

  // TEST: Historical data result
  String? _historicalTestResult;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeBackgroundSync();
    _loadUserInfo();
    _loadWeather();
  }


  /// Get greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning,';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon,';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening,';
    } else {
      return 'Good night,';
    }
  }

  /// Load user info from API
  Future<void> _loadUserInfo() async {
    final userInfo = await _authService.getUserInfo(forceRefresh: true);
    if (mounted) {
      setState(() {
        _userInfo = userInfo;
        _isLoadingUserInfo = false;
      });
    }
  }

  /// Refresh all data (pull-to-refresh)
  Future<void> _refreshData() async {
    await Future.wait([
      _loadUserInfo(),
      _loadWeather(),
    ]);
  }

  /// Load weather data from API
  Future<void> _loadWeather() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _isLoadingWeather = false);
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Fetch weather from API
      final weatherInfo = await _authService.getWeather(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        setState(() {
          _weatherInfo = weatherInfo;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Future<void> _loadSettings() async {
    final interval = await _syncService.getSyncInterval();
    final range = await _syncService.getHistoryRange();

    if (mounted) {
      setState(() {
        _syncInterval = _syncIntervalOptions.contains(interval) ? interval : 'Every 1 hour';
        _historyRange = _historyRangeOptions.contains(range) ? range : '1 week';
      });
    }
  }

  Future<void> _initializeBackgroundSync() async {
    await _syncService.initializeBackgroundSync();
    await _syncService.scheduleBackgroundSync();
  }

  void _updateSyncState(SyncState state, String message, int current, int total) {
    if (mounted) {
      setState(() {
        _syncState = state;
        _syncMessage = message;
      });
    }
  }

  String _getSyncButtonText() {
    switch (_syncState) {
      case SyncState.idle:
        return 'Sync Now';
      case SyncState.requestingPermissions:
        return 'Requesting Permissions...';
      case SyncState.submittingFcm:
        return 'Registering Device...';
      case SyncState.uploadingArchive:
        return 'Uploading Archive...';
      case SyncState.syncingData:
        return _syncMessage.isNotEmpty ? _syncMessage : 'Syncing...';
      case SyncState.completed:
        return 'Sync Complete';
      case SyncState.error:
        return 'Retry Sync';
    }
  }

  void _handleStopSync() {
    // Cancel the sync in SyncService
    _syncService.cancelSync();
    setState(() {
      _syncCancelled = true;
      _syncMessage = 'Cancelling...';
    });
  }

  void _onSyncCancelled() {
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _syncState = SyncState.idle;
        _syncMessage = '';
        _syncCancelled = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sync cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _syncCancelled = false;
      _syncState = SyncState.requestingPermissions;
      _syncMessage = '';
    });

    try {
      // 1. Request notification permission
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permission is required for sync updates'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Check if cancelled
      if (_syncCancelled) {
        _onSyncCancelled();
        return;
      }

      // 2. Request ALL Health Connect permissions via native code
      final healthResult = await _healthService.requestAllPermissionsNative();

      if (mounted) {
        if (healthResult['success'] != true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(healthResult['message'] ?? 'Some permissions were not granted'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // Check if cancelled
      if (_syncCancelled) {
        _onSyncCancelled();
        return;
      }

      // 3. Submit FCM token to server
      setState(() {
        _syncState = SyncState.submittingFcm;
        _syncMessage = 'Registering device...';
      });

      final fcmResult = await _authService.submitFcmToken();
      if (mounted && !fcmResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('FCM: ${fcmResult.message}'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Check if cancelled
      if (_syncCancelled) {
        _onSyncCancelled();
        return;
      }

      // 4. Perform health data sync with progress callback
      setState(() {
        _syncState = SyncState.syncingData;
        _syncMessage = 'Starting sync...';
      });

      final syncResult = await _syncService.performSync(
        onProgress: _updateSyncState,
        showNotifications: true,
      );

      if (mounted) {
        setState(() {
          _syncState = syncResult.success ? SyncState.completed : SyncState.error;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncResult.message),
            backgroundColor: syncResult.success ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _syncState = SyncState.error;
          _syncMessage = 'Error: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _syncCancelled = false;
        });
        // Reset to idle after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _syncState = SyncState.idle;
              _syncMessage = '';
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine isDark based on platform brightness or theme.
    // For now assuming system theme or light by default as per existing screens.
    // The HTML design supports both, we will implement primarily for Light/Dark adapting.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color surfaceColor = isDark ? AppColors.surfaceDark : Colors.white; // surface-light
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final Color mutedColor = isDark ? AppColors.textMuted : const Color(0xFF64748B); // slate-500

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.health_and_safety, // health_metrics equivalent
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'VitalGate',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings_outlined, color: mutedColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: AppColors.primary,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 140), // Space for fixed footer
                      children: [
                      // Greeting
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.inter(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ).createShader(bounds),
                              child: _isLoadingUserInfo
                                  ? SizedBox(
                                      height: 40,
                                      child: LoadingAnimationWidget.progressiveDots(
                                        color: AppColors.primary,
                                        size: 36,
                                      ),
                                    )
                                  : Text(
                                      _userInfo?.fullName ?? 'User',
                                      style: GoogleFonts.inter(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white, // Masked
                                        height: 1.1,
                                        letterSpacing: -1,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ready to sync your latest health metrics?',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Weather Widget
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ),
                          child: _isLoadingWeather
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: LoadingAnimationWidget.progressiveDots(
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                )
                              : _weatherInfo == null
                                  ? Row(
                                      children: [
                                        Icon(Icons.cloud_off, color: mutedColor, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Weather unavailable',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: mutedColor,
                                          ),
                                        ),
                                      ],
                                    )
                                  : LayoutBuilder(
                                      builder: (context, constraints) {
                                        // Weather content widgets
                                        final tempWidget = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.thermostat, color: AppColors.primary, size: 20),
                                            const SizedBox(width: 4),
                                            Text(
                                              _weatherInfo!.temperature,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.grey[200] : Colors.blueGrey[700],
                                              ),
                                            ),
                                          ],
                                        );

                                        final weatherWidget = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_weatherInfo!.iconUrl.isNotEmpty)
                                              CachedNetworkImage(
                                                imageUrl: _weatherInfo!.iconUrl,
                                                width: 24,
                                                height: 24,
                                                placeholder: (context, url) => const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                ),
                                                errorWidget: (context, url, error) => Icon(
                                                  Icons.cloud,
                                                  size: 20,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _weatherInfo!.weather,
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: mutedColor,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );

                                        final locationWidget = Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.location_on, size: 16, color: mutedColor),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _weatherInfo!.city.toUpperCase(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: mutedColor,
                                                  letterSpacing: 0.5,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        );

                                        final divider = Container(
                                          height: 16,
                                          width: 1,
                                          color: isDark ? Colors.white24 : Colors.black12,
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                        );

                                        // If width is less than 340, use column layout
                                        if (constraints.maxWidth < 340) {
                                          return Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  tempWidget,
                                                  divider,
                                                  Expanded(child: weatherWidget),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              locationWidget,
                                            ],
                                          );
                                        }

                                        // Wide layout: all in one row
                                        return Row(
                                          children: [
                                            tempWidget,
                                            divider,
                                            Expanded(child: weatherWidget),
                                            divider,
                                            locationWidget,
                                          ],
                                        );
                                      },
                                    ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sync Config Header
                      Padding(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         child: Row(
                           children: [
                             const Icon(Icons.tune, color: AppColors.primary),
                             const SizedBox(width: 8),
                             Text(
                               'Sync Configuration',
                               style: GoogleFonts.inter(
                                 fontSize: 18,
                                 fontWeight: FontWeight.w700,
                                 color: textColor,
                               ),
                             ),
                           ],
                         ),
                      ),
                      
                      const SizedBox(height: 20),

                      // TEST: Historical Data Result
                      if (_historicalTestResult != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TEST: Weight data from Jan 20, 2025',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _historicalTestResult!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Form Sections
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sync Interval
                            _buildLabel('SYNC INTERVAL', mutedColor),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: _syncInterval,
                              items: _syncIntervalOptions,
                              onChanged: (val) {
                                setState(() => _syncInterval = val!);
                                _syncService.setSyncInterval(val!);
                              },
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              borderColor: isDark ? Colors.white10 : Colors.black12,
                            ),

                            const SizedBox(height: 20),

                            // History Range
                            _buildLabel('HISTORY RANGE', mutedColor),
                            const SizedBox(height: 8),
                            _buildDropdown(
                              value: _historyRange,
                              items: _historyRangeOptions,
                              onChanged: (val) {
                                setState(() => _historyRange = val!);
                                _syncService.setHistoryRange(val!);
                              },
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              borderColor: isDark ? Colors.white10 : Colors.black12,
                            ),
                          ],
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Sticky Footer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      bgColor,
                      bgColor,
                      bgColor.withOpacity(0.0),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Sync button row with optional stop button
                    Row(
                      children: [
                        // Sync Now button (70% when syncing, 100% otherwise)
                        Expanded(
                          flex: _isSyncing ? 7 : 10,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSyncing ? null : _handleSync,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isSyncing
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _syncState == SyncState.completed
                                              ? Icons.check_circle
                                              : _syncState == SyncState.error
                                                  ? Icons.error_outline
                                                  : Icons.sync,
                                          color: Colors.white,
                                        ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      _getSyncButtonText(),
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Stop button (30% when syncing)
                        if (_isSyncing) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _handleStopSync,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    // API Status row (centered)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingAnimationWidget.beat(color: Colors.greenAccent, size: 10),
                        const SizedBox(width: 6),
                        Text(
                          'API Status: Online',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Color surfaceColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
          dropdownColor: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
