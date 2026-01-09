import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;
  bool _showValidation = false;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'));
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasNumber && _hasSpecialChar;

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please meet all password requirements'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final Color surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final Color textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final Color mutedColor = isDark ? AppColors.textMuted : const Color(0xFF64748B);
    final Color borderColor = isDark ? const Color(0xFF2D3139) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: borderColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: textColor,
                    padding: EdgeInsets.zero,
                  ),
                  Expanded(
                    child: Text(
                      'Change Password',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Instructional Text
                      Text(
                        'Your new password must be different from previously used passwords. Ensure your account remains secure.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: mutedColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Current Password
                      _buildLabel('Current Password', textColor),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _currentPasswordController,
                        hint: 'Enter current password',
                        showPassword: _showCurrentPassword,
                        onToggleVisibility: () {
                          setState(() => _showCurrentPassword = !_showCurrentPassword);
                        },
                        prefixIcon: Icons.lock_outline,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        borderColor: borderColor,
                        mutedColor: mutedColor,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            // TODO: Forgot password flow
                          },
                          child: Text(
                            'Forgot your password?',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(color: borderColor.withOpacity(0.5)),
                      const SizedBox(height: 24),

                      // New Password
                      _buildLabel('New Password', textColor),
                      const SizedBox(height: 8),
                      Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus && !_showValidation) {
                            setState(() => _showValidation = true);
                          }
                        },
                        child: _buildPasswordField(
                          controller: _newPasswordController,
                          hint: 'Enter new password',
                          showPassword: _showNewPassword,
                          onToggleVisibility: () {
                            setState(() => _showNewPassword = !_showNewPassword);
                          },
                          prefixIcon: Icons.key,
                          surfaceColor: surfaceColor,
                          textColor: textColor,
                          borderColor: borderColor,
                          mutedColor: mutedColor,
                        ),
                      ),

                      // Password Requirements (shown when focused)
                      if (_showValidation) ...[
                        const SizedBox(height: 12),
                        _buildRequirementsList(mutedColor),
                      ],

                      const SizedBox(height: 24),

                      // Confirm Password
                      _buildLabel('Confirm New Password', textColor),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hint: 'Re-enter new password',
                        showPassword: _showConfirmPassword,
                        onToggleVisibility: () {
                          setState(() => _showConfirmPassword = !_showConfirmPassword);
                        },
                        prefixIcon: Icons.lock_reset,
                        surfaceColor: surfaceColor,
                        textColor: textColor,
                        borderColor: borderColor,
                        mutedColor: mutedColor,
                      ),

                      const SizedBox(height: 100), // Space for button
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Button
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(
              color: borderColor.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleChangePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Change Password',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    required IconData prefixIcon,
    required Color surfaceColor,
    required Color textColor,
    required Color borderColor,
    required Color mutedColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        style: GoogleFonts.inter(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 16,
            color: mutedColor,
          ),
          prefixIcon: Icon(prefixIcon, color: mutedColor, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggleVisibility,
            icon: Icon(
              showPassword ? Icons.visibility : Icons.visibility_off,
              color: mutedColor,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field is required';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRequirementsList(Color mutedColor) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildRequirement('At least 8 characters', _hasMinLength, mutedColor),
        _buildRequirement('1 special character', _hasSpecialChar, mutedColor),
        _buildRequirement('1 uppercase letter', _hasUppercase, mutedColor),
        _buildRequirement('1 number', _hasNumber, mutedColor),
      ],
    );
  }

  Widget _buildRequirement(String text, bool isMet, Color mutedColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? Colors.green : mutedColor,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isMet ? Colors.green : mutedColor,
          ),
        ),
      ],
    );
  }
}
