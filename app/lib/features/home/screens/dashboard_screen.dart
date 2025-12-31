import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/services/health_service.dart';
import 'package:vitalgate/core/services/auth_service.dart';
import 'package:vitalgate/core/services/sync_service.dart';
import 'package:vitalgate/features/settings/screens/permissions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _syncInterval = 'Every 1 hour';
  String _historyRange = '1 week';
  bool _isSyncing = false;
  bool _wantUploadOldHistory = false;
  String? _selectedArchivePath;
  String? _selectedArchiveName;

  // Sync state for button text
  SyncState _syncState = SyncState.idle;
  String _syncMessage = '';

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeBackgroundSync();
  }

  Future<void> _loadSettings() async {
    final interval = await _syncService.getSyncInterval();
    final range = await _syncService.getHistoryRange();
    final wantOldHistory = await _syncService.getWantUploadOldHistory();

    if (mounted) {
      setState(() {
        _syncInterval = _syncIntervalOptions.contains(interval) ? interval : 'Every 1 hour';
        _historyRange = _historyRangeOptions.contains(range) ? range : '1 week';
        _wantUploadOldHistory = wantOldHistory;
      });
    }
  }

  Future<void> _initializeBackgroundSync() async {
    await _syncService.initializeBackgroundSync();
    await _syncService.scheduleBackgroundSync();
  }

  Future<void> _pickArchiveFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedArchivePath = result.files.single.path;
          _selectedArchiveName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _handleSync() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
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

      // 4. Upload archive file if selected
      if (_wantUploadOldHistory && _selectedArchivePath != null) {
        setState(() {
          _syncState = SyncState.uploadingArchive;
          _syncMessage = 'Uploading archive...';
        });

        final archiveUploaded = await _syncService.uploadArchiveFile(
          filePath: _selectedArchivePath!,
        );
        if (mounted) {
          if (archiveUploaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Archive uploaded successfully'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() {
              _selectedArchivePath = null;
              _selectedArchiveName = null;
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload archive'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }

      // 5. Perform health data sync with progress callback
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
        setState(() => _isSyncing = false);
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
                              builder: (context) => const PermissionsScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.settings_outlined, color: mutedColor),
                      ),
                    ],
                  ),
                ),

                Expanded(
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
                              'Good afternoon,',
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
                              child: Text(
                                'Eldar',
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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // If width is less than 340, use column layout
                              if (constraints.maxWidth < 340) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // First row: Temperature + Weather
                                    Row(
                                      children: [
                                        Icon(Icons.thermostat, color: AppColors.primary, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '24°C',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? Colors.grey[200] : Colors.blueGrey[700],
                                          ),
                                        ),
                                        Container(
                                          height: 16,
                                          width: 1,
                                          color: isDark ? Colors.white24 : Colors.black12,
                                          margin: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Cloudy, windy',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: mutedColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Second row: Location
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: mutedColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'SAN FRANCISCO',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: mutedColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              }
                              // Wide layout: all in one row
                              return Row(
                                children: [
                                  Icon(Icons.thermostat, color: AppColors.primary, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '24°C',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[200] : Colors.blueGrey[700],
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    width: 1,
                                    color: isDark ? Colors.white24 : Colors.black12,
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Cloudy, windy',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: mutedColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 16,
                                    width: 1,
                                    color: isDark ? Colors.white24 : Colors.black12,
                                    margin: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  Icon(Icons.location_on, size: 16, color: mutedColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'SAN FRANCISCO',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: mutedColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
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

                            const SizedBox(height: 20),

                            // Upload Old History Checkbox
                            InkWell(
                              onTap: () {
                                setState(() => _wantUploadOldHistory = !_wantUploadOldHistory);
                                _syncService.setWantUploadOldHistory(!_wantUploadOldHistory);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: _wantUploadOldHistory ? AppColors.primary : Colors.transparent,
                                        border: Border.all(
                                          color: _wantUploadOldHistory ? AppColors.primary : mutedColor,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: _wantUploadOldHistory
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'I want to upload old history',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Large History Alert - only show when checkbox is checked
                            if (_wantUploadOldHistory) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Large History Detected',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: textColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Syncing more than 30 days requires a local archive file to avoid API rate limits.',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: mutedColor,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Upload Area - File Picker
                              DottedBorder(
                                color: AppColors.primary.withOpacity(0.3),
                                strokeWidth: 2,
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                dashPattern: const [6, 6],
                                child: Container(
                                  height: 112,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.black12 : const Color(0xfff8fafc).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: _pickArchiveFile,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _selectedArchiveName != null ? Icons.check_circle : Icons.upload_file,
                                          size: 36,
                                          color: _selectedArchiveName != null ? Colors.green : AppColors.primary,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _selectedArchiveName ?? 'Click to upload archive',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _selectedArchiveName != null
                                                ? Colors.green
                                                : (isDark ? Colors.grey[300] : Colors.blueGrey[700]),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ZIP ONLY (MAX. 50MB)',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: mutedColor,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
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
                    Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(16), // xl
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            LoadingAnimationWidget.beat(color: Colors.greenAccent, size: 10), // emerald -> greenAccent
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
                        GestureDetector(
                          onTap: () {
                             // Logout stub
                             Navigator.of(context).pop(); 
                          },
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 18, color: mutedColor),
                              const SizedBox(width: 6),
                              Text(
                                'Logout',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: mutedColor,
                                ),
                              ),
                            ],
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
