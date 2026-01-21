import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/auth_service.dart';
import 'package:vitalgate/features/profile/screens/edit_body_stats_screen.dart';
import 'package:vitalgate/features/profile/screens/metric_detail_screen.dart';

class BodyStatsScreen extends StatefulWidget {
  const BodyStatsScreen({super.key});

  @override
  State<BodyStatsScreen> createState() => _BodyStatsScreenState();
}

class _BodyStatsScreenState extends State<BodyStatsScreen> {
  final AuthService _authService = AuthService();
  BodyStats? _bodyStats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBodyStats();
  }

  Future<void> _loadBodyStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final stats = await _authService.getBodyStats();
      if (mounted) {
        setState(() {
          _bodyStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textLight;
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF2C2F35) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor.withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Body Stats',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBodyStatsScreen(initialStats: _bodyStats),
                ),
              );
              if (result == true) {
                _loadBodyStats(); // Refresh data after edit
              }
            },
            child: Text(
              'Edit',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: borderColor,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.progressiveDots(
                color: AppColors.primary,
                size: 48,
              ),
            )
          : _error != null
              ? _buildErrorState(textColor, mutedColor)
              : RefreshIndicator(
                  onRefresh: _loadBodyStats,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Stats
                        _buildSummaryStats(isDark, surfaceColor, textColor, mutedColor, borderColor),
                        const SizedBox(height: 24),

                        // Torso Section
                        _buildSectionTitle('Torso', textColor),
                        const SizedBox(height: 12),
                        _buildTorsoSection(isDark, surfaceColor, textColor, mutedColor, borderColor),
                        const SizedBox(height: 24),

                        // Arms & Shoulders Section
                        _buildSectionTitle('Arms & Shoulders', textColor),
                        const SizedBox(height: 12),
                        _buildArmsSection(isDark, surfaceColor, textColor, mutedColor, borderColor),
                        const SizedBox(height: 24),

                        // Legs Section
                        _buildSectionTitle('Legs', textColor),
                        const SizedBox(height: 12),
                        _buildLegsSection(isDark, surfaceColor, textColor, mutedColor, borderColor),
                        const SizedBox(height: 80), // Space for FAB
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => EditBodyStatsScreen(initialStats: _bodyStats),
            ),
          );
          if (result == true) {
            _loadBodyStats();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildErrorState(Color textColor, Color mutedColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: mutedColor),
            const SizedBox(height: 16),
            Text(
              'Failed to load body stats',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBodyStats,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  void _navigateToDetail(String field) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MetricDetailScreen(field: field),
      ),
    );
  }

  Widget _buildSummaryStats(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return Row(
      children: [
        // Weight
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Weight',
            value: _bodyStats?.weight?.toStringAsFixed(1) ?? '-',
            unit: 'kg',
            field: 'weight',
            isDark: isDark,
            surfaceColor: surfaceColor,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(width: 12),
        // Height
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.height,
            label: 'Height',
            value: _bodyStats?.height?.toStringAsFixed(0) ?? '-',
            unit: 'cm',
            field: 'height',
            isDark: isDark,
            surfaceColor: surfaceColor,
            textColor: textColor,
            mutedColor: mutedColor,
            borderColor: borderColor,
          ),
        ),
        const SizedBox(width: 12),
        // BMI
        Expanded(
          child: _buildBmiCard(isDark),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required String field,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDetail(field),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: mutedColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiCard(bool isDark) {
    final bmiValue = _bodyStats?.bmi;
    final bmiCategory = _bodyStats?.bmiCategory ?? '-';

    return GestureDetector(
      onTap: () => _navigateToDetail('bmi'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF3558A0)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 20, color: Colors.white.withOpacity(0.8)),
                const SizedBox(width: 6),
                Text(
                  'BMI',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  bmiValue?.toStringAsFixed(1) ?? '-',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              bmiCategory,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTorsoSection(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildTorsoCard(
          icon: Icons.person_outline,
          label: 'Neck',
          value: _bodyStats?.neck,
          field: 'neck',
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
        _buildTorsoCard(
          icon: Icons.checkroom_outlined,
          label: 'Chest',
          value: _bodyStats?.chest,
          field: 'chest',
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
        _buildTorsoCard(
          icon: Icons.straighten,
          label: 'Waist',
          value: _bodyStats?.waist,
          field: 'waist',
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
        _buildTorsoCard(
          icon: Icons.accessibility_new,
          label: 'Hips',
          value: _bodyStats?.hips,
          field: 'hips',
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
      ],
    );
  }

  Widget _buildTorsoCard({
    required IconData icon,
    required String label,
    required double? value,
    required String field,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: () => _navigateToDetail(field),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2F35) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: textColor),
                ),
                Text(
                  'cm',
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: mutedColor,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value?.toStringAsFixed(1) ?? '-',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArmsSection(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildCompactCard('Shoulders', _bodyStats?.shoulders, Icons.accessibility, false, 'shoulders', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('R Bicep', _bodyStats?.rightBicep, Icons.fitness_center, false, 'right_arm', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('L Bicep', _bodyStats?.leftBicep, Icons.fitness_center, true, 'left_arm', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('R Forearm', _bodyStats?.rightForearm, Icons.pan_tool, false, 'right_forearm', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('L Forearm', _bodyStats?.leftForearm, Icons.pan_tool, true, 'left_forearm', isDark, surfaceColor, textColor, mutedColor, borderColor),
      ],
    );
  }

  Widget _buildLegsSection(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildCompactCard('R Thigh', _bodyStats?.rightThigh, Icons.directions_run, false, 'right_thigh', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('L Thigh', _bodyStats?.leftThigh, Icons.directions_run, true, 'left_thigh', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('R Calve', _bodyStats?.rightCalve, Icons.directions_walk, false, 'right_calve', isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactCard('L Calve', _bodyStats?.leftCalve, Icons.directions_walk, true, 'left_calve', isDark, surfaceColor, textColor, mutedColor, borderColor),
      ],
    );
  }

  Widget _buildCompactCard(String label, double? value, IconData icon, bool flipIcon, String field, bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return GestureDetector(
      onTap: () => _navigateToDetail(field),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Transform(
                  alignment: Alignment.center,
                  transform: flipIcon ? (Matrix4.identity()..scale(-1.0, 1.0, 1.0)) : Matrix4.identity(),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: mutedColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: value?.toStringAsFixed(1) ?? '-',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        TextSpan(
                          text: ' cm',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: mutedColor,
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
    );
  }
}
