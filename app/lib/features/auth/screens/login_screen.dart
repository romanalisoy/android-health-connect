import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/health_service.dart';
import '../../home/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _baseUrl;

  @override
  void initState() {
    super.initState();
    _loadBaseUrl();
  }

  Future<void> _loadBaseUrl() async {
    final url = await AuthService().getBaseUrl();
    if (mounted) {
      setState(() {
        _baseUrl = url;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // 1. Validation
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 2. Login
    final result = await AuthService().login(email, password);

    if (!result.success) {
      _showError(result.message);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 3. Submit FCM Token
    final fcmResult = await AuthService().submitFcmToken();
    
    if (!fcmResult.success) {
      // Login worked, but FCM failed. 
      // We show the FCM error but still consider user logged in? 
      // Or we can just append it to the success message or show a separate warning.
      // For now, let's show it as an error but proceed, or maybe just a Toast.
      // Or better: Show success for login, but warn about FCM.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login success, but FCM failed: ${fcmResult.message}'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
       _showSuccess(result.message);
    }

    // 4. Request Permissions (Health Connect + Location)
    // We do this regardless of FCM success/failure as long as login worked.
    // Show a loading indicator or message if needed, but the system dialogs will appear on top.
    try {
      final bool permissionsGranted = await HealthService().requestPermissions();
      if (!permissionsGranted) {
        _showError('Some permissions were not granted. Health data may not sync.');
      }
    } catch (e) {
      _showError('Error requesting permissions: $e');
    }
    
    // Navigate to Dashboard and clear entire navigation stack
    if (mounted) {
       Navigator.pushAndRemoveUntil(
         context,
         MaterialPageRoute(builder: (context) => const DashboardScreen()),
         (route) => false, // Remove all previous routes (including HostSelectionScreen)
       );
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent, 
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new, 
                        size: 24,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     // Title
                    Text(
                      'Log In',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Subtitle
                    Text(
                      'Enter your credentials to sync your health data with your VitalGate server.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? AppColors.textMuted : const Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Email Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Email Address',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          style: GoogleFonts.inter(
                             fontSize: 16,
                             color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'name@example.com',
                            hintStyle: TextStyle(
                              color: isDark ? AppColors.textMuted : Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Password Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Password',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Stack(
                          children: [
                             TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enabled: !_isLoading,
                              style: GoogleFonts.inter(
                                 fontSize: 16,
                                 color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••••••',
                                hintStyle: TextStyle(
                                  color: isDark ? AppColors.textMuted : Colors.grey.shade400,
                                ),
                                contentPadding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                }, 
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  color: isDark ? AppColors.textMuted : Colors.grey.shade400,
                                ),
                              ),
                            )
                          ],
                        ),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    
                    // Login Button
                    Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4E72B8), Color(0xFF6B89C7)],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleLogin,
                          borderRadius: BorderRadius.circular(12),
                          child: Center(
                            child: _isLoading 
                            ? LoadingAnimationWidget.staggeredDotsWave(
                                color: Colors.white,
                                size: 32,
                              )
                            : Text(
                              'Log In',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Connection Info Pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.grey.shade200.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                             const Icon(Icons.dns, size: 14, color: AppColors.primary),
                             const SizedBox(width: 8),
                             Flexible(
                               child: Text(
                                 'Connecting to: ${_baseUrl?.replaceAll(RegExp(r'^https?://'), '') ?? "..."}',
                                 style: GoogleFonts.inter(
                                   fontSize: 12,
                                   fontWeight: FontWeight.w500,
                                   color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                          ],
                        ),
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
}
