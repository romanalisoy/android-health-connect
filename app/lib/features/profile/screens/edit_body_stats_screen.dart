import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/auth_service.dart';

class EditBodyStatsScreen extends StatefulWidget {
  final BodyStats? initialStats;

  const EditBodyStatsScreen({super.key, this.initialStats});

  @override
  State<EditBodyStatsScreen> createState() => _EditBodyStatsScreenState();
}

class _EditBodyStatsScreenState extends State<EditBodyStatsScreen> {
  final AuthService _authService = AuthService();
  bool _isSaving = false;

  // Controllers for torso
  final _neckController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();

  // Controllers for arms & shoulders
  final _rightShoulderController = TextEditingController();
  final _leftShoulderController = TextEditingController();
  final _rightArmController = TextEditingController();
  final _leftArmController = TextEditingController();
  final _rightForearmController = TextEditingController();
  final _leftForearmController = TextEditingController();

  // Controllers for legs
  final _rightThighController = TextEditingController();
  final _leftThighController = TextEditingController();
  final _rightCalveController = TextEditingController();
  final _leftCalveController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final stats = widget.initialStats;
    if (stats != null) {
      _neckController.text = stats.neck?.toStringAsFixed(1) ?? '';
      _chestController.text = stats.chest?.toStringAsFixed(1) ?? '';
      _waistController.text = stats.waist?.toStringAsFixed(1) ?? '';
      _hipsController.text = stats.hips?.toStringAsFixed(1) ?? '';
      _rightShoulderController.text = stats.rightShoulder?.toStringAsFixed(1) ?? '';
      _leftShoulderController.text = stats.leftShoulder?.toStringAsFixed(1) ?? '';
      _rightArmController.text = stats.rightBicep?.toStringAsFixed(1) ?? '';
      _leftArmController.text = stats.leftBicep?.toStringAsFixed(1) ?? '';
      _rightForearmController.text = stats.rightForearm?.toStringAsFixed(1) ?? '';
      _leftForearmController.text = stats.leftForearm?.toStringAsFixed(1) ?? '';
      _rightThighController.text = stats.rightThigh?.toStringAsFixed(1) ?? '';
      _leftThighController.text = stats.leftThigh?.toStringAsFixed(1) ?? '';
      _rightCalveController.text = stats.rightCalve?.toStringAsFixed(1) ?? '';
      _leftCalveController.text = stats.leftCalve?.toStringAsFixed(1) ?? '';
    }
  }

  @override
  void dispose() {
    _neckController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _rightShoulderController.dispose();
    _leftShoulderController.dispose();
    _rightArmController.dispose();
    _leftArmController.dispose();
    _rightForearmController.dispose();
    _leftForearmController.dispose();
    _rightThighController.dispose();
    _leftThighController.dispose();
    _rightCalveController.dispose();
    _leftCalveController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Build the data map - send 0 for empty fields
    final data = <String, double>{};

    double parseOrZero(TextEditingController controller) {
      final text = controller.text.trim();
      if (text.isEmpty) return 0;
      final value = double.tryParse(text);
      if (value != null && value >= 0 && value <= 500) {
        return value;
      }
      return 0;
    }

    data['neck'] = parseOrZero(_neckController);
    data['chest'] = parseOrZero(_chestController);
    data['waist'] = parseOrZero(_waistController);
    data['hips'] = parseOrZero(_hipsController);
    data['right_shoulder'] = parseOrZero(_rightShoulderController);
    data['left_shoulder'] = parseOrZero(_leftShoulderController);
    data['right_arm'] = parseOrZero(_rightArmController);
    data['left_arm'] = parseOrZero(_leftArmController);
    data['right_forearm'] = parseOrZero(_rightForearmController);
    data['left_forearm'] = parseOrZero(_leftForearmController);
    data['right_thigh'] = parseOrZero(_rightThighController);
    data['left_thigh'] = parseOrZero(_leftThighController);
    data['right_calve'] = parseOrZero(_rightCalveController);
    data['left_calve'] = parseOrZero(_leftCalveController);

    setState(() => _isSaving = true);

    try {
      final result = await _authService.updateBodyStats(data);
      if (mounted) {
        setState(() => _isSaving = false);
        if (result.success) {
          _showSnackBar('Body stats updated successfully');
          Navigator.pop(context, true); // Return true to indicate refresh needed
        } else {
          _showSnackBar(result.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar('Error: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Body Stats',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info note about weight/height
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Weight and height are synced from Health Connect',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
              ],
            ),
          ),

          // Save Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark.withOpacity(0.9)
                    : Colors.white.withOpacity(0.9),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? LoadingAnimationWidget.progressiveDots(
                          color: Colors.white,
                          size: 24,
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildTorsoSection(bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _buildTorsoInputCard(
          icon: Icons.person_outline,
          label: 'Neck',
          controller: _neckController,
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
        _buildTorsoInputCard(
          icon: Icons.checkroom_outlined,
          label: 'Chest',
          controller: _chestController,
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
        _buildTorsoInputCard(
          icon: Icons.straighten,
          label: 'Waist',
          controller: _waistController,
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
        _buildTorsoInputCard(
          icon: Icons.accessibility_new,
          label: 'Hips',
          controller: _hipsController,
          isDark: isDark,
          surfaceColor: surfaceColor,
          textColor: textColor,
          mutedColor: mutedColor,
          borderColor: borderColor,
        ),
      ],
    );
  }

  Widget _buildTorsoInputCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isDark,
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
  }) {
    return Container(
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
                style: GoogleFonts.robotoMono(fontSize: 11, color: mutedColor),
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
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary, width: 2),
              ),
              hintText: '-',
              hintStyle: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: mutedColor.withOpacity(0.5),
              ),
            ),
          ),
        ],
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
        _buildCompactInputCard('R Shoulder', _rightShoulderController, Icons.accessibility, false, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('L Shoulder', _leftShoulderController, Icons.accessibility, true, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('R Bicep', _rightArmController, Icons.fitness_center, false, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('L Bicep', _leftArmController, Icons.fitness_center, true, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('R Forearm', _rightForearmController, Icons.pan_tool, false, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('L Forearm', _leftForearmController, Icons.pan_tool, true, isDark, surfaceColor, textColor, mutedColor, borderColor),
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
        _buildCompactInputCard('R Thigh', _rightThighController, Icons.directions_run, false, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('L Thigh', _leftThighController, Icons.directions_run, true, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('R Calve', _rightCalveController, Icons.directions_walk, false, isDark, surfaceColor, textColor, mutedColor, borderColor),
        _buildCompactInputCard('L Calve', _leftCalveController, Icons.directions_walk, true, isDark, surfaceColor, textColor, mutedColor, borderColor),
      ],
    );
  }

  Widget _buildCompactInputCard(String label, TextEditingController controller, IconData icon, bool flipIcon, bool isDark, Color surfaceColor, Color textColor, Color mutedColor, Color borderColor) {
    return Container(
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          hintText: '-',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: mutedColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      'cm',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
