import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/auth_service.dart';
import 'package:vitalgate/features/settings/screens/permissions_screen.dart';
import 'package:vitalgate/features/auth/screens/hostname_selection_screen.dart';
import 'package:vitalgate/features/profile/screens/change_password_screen.dart';
import 'package:vitalgate/features/profile/screens/basic_info_screen.dart';
import 'package:vitalgate/features/profile/screens/old_data_screen.dart';
import 'package:vitalgate/features/profile/screens/body_stats_screen.dart';
import 'package:vitalgate/features/profile/screens/sync_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserInfo? _userInfo;
  String? _baseUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await _authService.getUserInfo(forceRefresh: true);
    final baseUrl = await _authService.getBaseUrl();
    if (mounted) {
      setState(() {
        _userInfo = userInfo;
        _baseUrl = baseUrl;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Logout',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textLight,
            ),
          ),
          content: Text(
            'Are you sure you want to logout? All local data will be cleared.',
            style: GoogleFonts.inter(
              color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: isDark ? AppColors.textMuted : const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Logout',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Clear all stored data
      await _authService.logout();
      _authService.clearUserCache();

      // Clear all SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to hostname selection and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HostSelectionScreen()),
          (route) => false,
        );
      }
    }
  }

  /// Generate avatar color from name
  Color _getAvatarColor(String? name) {
    if (name == null || name.isEmpty) return AppColors.primary;
    final colors = [
      const Color(0xFF4C70B8),
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFF06B6D4),
    ];
    return colors[name.codeUnits.fold(0, (sum, c) => sum + c) % colors.length];
  }

  /// Show profile picture in full screen
  void _showFullScreenImage() {
    final imageUrl = _userInfo?.getFullProfilePictureUrl(_baseUrl);
    if (imageUrl == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          heroTag: 'profile-avatar-main',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final Color mutedColor = isDark ? AppColors.textMuted : const Color(0xFF64748B);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.9),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      color: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  // Title
                  Expanded(
                    child: Text(
                      'Profile',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  // Edit button placeholder (for balance)
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: LoadingAnimationWidget.progressiveDots(
                        color: AppColors.primary,
                        size: 40,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadUserInfo,
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                        // Profile Section
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              // Avatar - Clickable for fullscreen
                              GestureDetector(
                                onTap: _userInfo?.getFullProfilePictureUrl(_baseUrl) != null
                                    ? _showFullScreenImage
                                    : null,
                                child: Hero(
                                  tag: 'profile-avatar-main',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: bgColor,
                                          width: 4,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: _userInfo?.getFullProfilePictureUrl(_baseUrl) != null
                                            ? CachedNetworkImage(
                                                imageUrl: _userInfo!.getFullProfilePictureUrl(_baseUrl)!,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) => _buildInitialsAvatar(),
                                                errorWidget: (context, url, error) => _buildInitialsAvatar(),
                                              )
                                            : _buildInitialsAvatar(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Name
                              Text(
                                _userInfo?.fullName ?? 'User',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Email
                              Text(
                                _userInfo?.email ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Self-Hosted Active',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Account Settings Section
                        Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 12),
                          child: Text(
                            'ACCOUNT SETTINGS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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
                            children: [
                              _buildSettingsItem(
                                icon: Icons.badge_outlined,
                                iconColor: const Color(0xFF3B82F6),
                                iconBgColor: const Color(0xFF3B82F6).withOpacity(0.1),
                                title: 'Basic Information',
                                subtitle: 'Name, email, birth date',
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                showBorder: true,
                                onTap: () async {
                                  final result = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const BasicInfoScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserInfo();
                                  }
                                },
                              ),
                              _buildSettingsItem(
                                icon: Icons.history,
                                iconColor: const Color(0xFF6366F1),
                                iconBgColor: const Color(0xFF6366F1).withOpacity(0.1),
                                title: 'Old data',
                                subtitle: 'Historical records',
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                showBorder: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const OldDataScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildSettingsItem(
                                icon: Icons.sync,
                                iconColor: const Color(0xFFEC4899),
                                iconBgColor: const Color(0xFFEC4899).withOpacity(0.1),
                                title: 'Sync History',
                                subtitle: 'Recent synchronization logs',
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                showBorder: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SyncHistoryScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildSettingsItem(
                                icon: Icons.accessibility_new,
                                iconColor: const Color(0xFF8B5CF6),
                                iconBgColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                                title: 'Body Stats',
                                subtitle: 'Height, weight, measurements',
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                showBorder: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BodyStatsScreen()),
                                  );
                                },
                              ),
                              _buildSettingsItem(
                                icon: Icons.lock_reset,
                                iconColor: const Color(0xFFF97316),
                                iconBgColor: const Color(0xFFF97316).withOpacity(0.1),
                                title: 'Change Password',
                                subtitle: 'Security updates',
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                showBorder: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ChangePasswordScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildSettingsItem(
                                icon: Icons.verified_user_outlined,
                                iconColor: const Color(0xFF14B8A6),
                                iconBgColor: const Color(0xFF14B8A6).withOpacity(0.1),
                                title: 'Permissions',
                                subtitle: 'Health Connect & API access',
                                textColor: textColor,
                                mutedColor: mutedColor,
                                borderColor: borderColor,
                                showBorder: false,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PermissionsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Logout Button
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _handleLogout,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.logout,
                                      color: Colors.red,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Logout',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Version Info
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'VitalGate Android v1.1.0 (Build 2)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: mutedColor.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<String?>(
                                future: _authService.getBaseUrl(),
                                builder: (context, snapshot) {
                                  final baseUrl = snapshot.data ?? '';
                                  final serverHost = Uri.tryParse(baseUrl)?.host ?? 'unknown';
                                  return Text(
                                    'Server: $serverHost',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: mutedColor.withOpacity(0.5),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final avatarColor = _getAvatarColor(_userInfo?.fullName);
    return Container(
      color: avatarColor,
      child: Center(
        child: Text(
          _userInfo?.initials ?? '?',
          style: GoogleFonts.inter(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required bool showBorder,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: showBorder
                ? Border(
                    bottom: BorderSide(
                      color: borderColor,
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: mutedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full screen image viewer with hero animation
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Stack(
          children: [
            // Image
            Center(
              child: Hero(
                tag: heroTag,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
