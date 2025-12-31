import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/health_service.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final HealthService _healthService = HealthService();
  bool _isLoading = true;
  Map<String, List<Map<String, dynamic>>> _groupedPermissions = {};

  // System permissions status
  bool _notificationGranted = false;
  bool _locationGranted = false;
  bool _storageGranted = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    setState(() => _isLoading = true);

    try {
      // Load Health Connect permissions
      final permissions = await _healthService.getPermissionsList();

      // Group by category
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final perm in permissions) {
        final category = perm['category'] as String;
        grouped.putIfAbsent(category, () => []);
        grouped[category]!.add(perm);
      }

      // Load system permissions
      _notificationGranted = await Permission.notification.isGranted;
      _locationGranted = await Permission.location.isGranted;
      _storageGranted = await Permission.storage.isGranted;

      setState(() {
        _groupedPermissions = grouped;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final Color mutedColor = isDark ? AppColors.textMuted : const Color(0xFF64748B);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back, color: mutedColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'App Permissions',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadPermissions,
                    icon: Icon(Icons.refresh, color: AppColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadPermissions,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          // Description
                          Text(
                            'Review the data access permissions for VitalGate. These permissions are required to sync your metrics to the API.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: mutedColor,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Health Data Permissions
                          ..._groupedPermissions.entries.map((entry) {
                            return _buildPermissionSection(
                              title: entry.key,
                              permissions: entry.value,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              mutedColor: mutedColor,
                              borderColor: borderColor,
                              isDark: isDark,
                            );
                          }),

                          // System Permissions
                          _buildSystemPermissionsSection(
                            surfaceColor: surfaceColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            borderColor: borderColor,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 24),

                          // Privacy Info Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.05),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.verified_user,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Data Stays Yours',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'VitalGate is open-source and self-hosted. We do not transmit your data to any third-party analytics services.',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: mutedColor,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      GestureDetector(
                                        onTap: () {
                                          // TODO: Open privacy policy
                                        },
                                        child: Text(
                                          'Read Privacy Policy',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }

  Widget _buildPermissionSection({
    required String title,
    required List<Map<String, dynamic>> permissions,
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mutedColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: permissions.asMap().entries.map((entry) {
              final index = entry.key;
              final perm = entry.value;
              final isLast = index == permissions.length - 1;
              final granted = perm['granted'] as bool? ?? false;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        perm['name'] as String? ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    Icon(
                      granted ? Icons.check_circle : Icons.cancel,
                      color: granted ? Colors.green : Colors.red.withOpacity(0.6),
                      size: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSystemPermissionsSection({
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final systemPermissions = [
      {'name': 'Notifications', 'description': 'Sync status updates', 'granted': _notificationGranted},
      {'name': 'Location', 'description': 'Local weather data', 'granted': _locationGranted},
      {'name': 'Storage', 'description': 'Required for backups', 'granted': _storageGranted},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'SYSTEM & STORAGE',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: mutedColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: systemPermissions.asMap().entries.map((entry) {
              final index = entry.key;
              final perm = entry.value;
              final isLast = index == systemPermissions.length - 1;
              final granted = perm['granted'] as bool;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            perm['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            perm['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      granted ? Icons.check_circle : Icons.cancel,
                      color: granted ? Colors.green : Colors.red.withOpacity(0.6),
                      size: 20,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
