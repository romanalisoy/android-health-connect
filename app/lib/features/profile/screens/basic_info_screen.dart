import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import 'package:vitalgate/core/services/auth_service.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _birthdate;

  UserInfo? _userInfo;
  String? _baseUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final userInfo = await _authService.getUserInfo(forceRefresh: true);
    final baseUrl = await _authService.getBaseUrl();
    if (mounted) {
      setState(() {
        _userInfo = userInfo;
        _baseUrl = baseUrl;
        _fullNameController.text = userInfo?.fullName ?? '';
        _emailController.text = userInfo?.email ?? '';
        _birthdate = userInfo?.birthdate;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isUploadingImage = true;
      });

      final result = await _authService.uploadProfilePicture(image.path);

      if (mounted) {
        setState(() => _isUploadingImage = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? Colors.green : Colors.red,
          ),
        );

        if (result.success) {
          // Refresh user info to get new profile picture URL
          await _loadUserInfo();
        } else {
          // Reset selected image on failure
          setState(() => _selectedImage = null);
        }
      }
    }
  }

  void _showFullScreenImage() {
    final imageUrl = _userInfo?.getFullProfilePictureUrl(_baseUrl);
    if (imageUrl == null && _selectedImage == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrl: imageUrl,
          localFile: _selectedImage,
          heroTag: 'profile-avatar',
        ),
      ),
    );
  }

  Future<void> _selectBirthdate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: AppColors.surfaceDark,
                    onSurface: AppColors.textDark,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textLight,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final result = await _authService.updateProfile(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      birthdate: _birthdate != null
          ? DateFormat('yyyy-MM-dd').format(_birthdate!)
          : null,
    );

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      if (result.success) {
        Navigator.pop(context, true);
      }
    }
  }

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
                      'Basic Information',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
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
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture Section
                            Center(
                              child: Stack(
                                children: [
                                  // Avatar - Clickable for fullscreen
                                  GestureDetector(
                                    onTap: (_userInfo?.getFullProfilePictureUrl(_baseUrl) != null || _selectedImage != null)
                                        ? _showFullScreenImage
                                        : null,
                                    child: Hero(
                                      tag: 'profile-avatar',
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.primary.withOpacity(0.3),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.2),
                                              blurRadius: 16,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: _isUploadingImage
                                              ? Container(
                                                  color: surfaceColor,
                                                  child: Center(
                                                    child: LoadingAnimationWidget.progressiveDots(
                                                      color: AppColors.primary,
                                                      size: 30,
                                                    ),
                                                  ),
                                                )
                                              : _selectedImage != null
                                                  ? Image.file(
                                                      _selectedImage!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : _userInfo?.getFullProfilePictureUrl(_baseUrl) != null
                                                      ? CachedNetworkImage(
                                                          imageUrl: _userInfo!.getFullProfilePictureUrl(_baseUrl)!,
                                                          fit: BoxFit.cover,
                                                          placeholder: (context, url) =>
                                                              _buildInitialsAvatar(surfaceColor),
                                                          errorWidget: (context, url, error) =>
                                                              _buildInitialsAvatar(surfaceColor),
                                                        )
                                                      : _buildInitialsAvatar(surfaceColor),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Edit Button
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: GestureDetector(
                                      onTap: _isUploadingImage ? null : _pickImage,
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: bgColor,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.primary.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Tap photo to view, tap pencil to change',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: mutedColor,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Full Name
                            _buildLabel('Full Name', textColor),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _fullNameController,
                              hint: 'Enter your full name',
                              prefixIcon: Icons.person_outline,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Email
                            _buildLabel('Email', textColor),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Enter your email',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              surfaceColor: surfaceColor,
                              textColor: textColor,
                              borderColor: borderColor,
                              mutedColor: mutedColor,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),

                            // Date of Birth
                            _buildLabel('Date of Birth', textColor),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _selectBirthdate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_outlined,
                                      color: mutedColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _birthdate != null
                                            ? DateFormat('MMMM d, yyyy').format(_birthdate!)
                                            : 'Select your birthdate',
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          color: _birthdate != null ? textColor : mutedColor,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: mutedColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),

      // Bottom Save Button
      bottomNavigationBar: _isLoading
          ? null
          : Container(
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
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
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
                              'Save Changes',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required Color surfaceColor,
    required Color textColor,
    required Color borderColor,
    required Color mutedColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
        keyboardType: keyboardType,
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildInitialsAvatar(Color surfaceColor) {
    final avatarColor = _getAvatarColor(_userInfo?.fullName);
    return Container(
      color: avatarColor,
      child: Center(
        child: Text(
          _userInfo?.initials ?? '?',
          style: GoogleFonts.inter(
            fontSize: 44,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Full screen image viewer with hero animation
class _FullScreenImageViewer extends StatelessWidget {
  final String? imageUrl;
  final File? localFile;
  final String heroTag;

  const _FullScreenImageViewer({
    this.imageUrl,
    this.localFile,
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
                  child: localFile != null
                      ? Image.file(
                          localFile!,
                          fit: BoxFit.contain,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
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
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
