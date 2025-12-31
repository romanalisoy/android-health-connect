import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:vitalgate/core/theme/app_colors.dart';
import '../../../../core/services/auth_service.dart';
import 'login_screen.dart';

class HostSelectionScreen extends StatefulWidget {
  const HostSelectionScreen({super.key});

  @override
  State<HostSelectionScreen> createState() => _HostSelectionScreenState();
}

class _HostSelectionScreenState extends State<HostSelectionScreen> {
  final TextEditingController _hostController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _hostController.dispose();
    super.dispose();
  }

  Future<void> _validateAndContinue() async {
    final String inputHtml = _hostController.text.trim();

    // 1. Validate Not Empty
    if (inputHtml.isEmpty) {
      _showError('Please enter an instance URL.');
      return;
    }

    // 2. Validate Protocol
    if (!inputHtml.startsWith('http://') && !inputHtml.startsWith('https://')) {
      _showError('Instance URL must start with http:// or https://');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Check Server Connectivity
      // Construct the status API URL. Remove trailing slash if present to avoid double slash.
      final String baseUrl = inputHtml.endsWith('/') 
          ? inputHtml.substring(0, inputHtml.length - 1) 
          : inputHtml;
      final Uri statusUrl = Uri.parse('$baseUrl/api/v1/status');

      final response = await http.get(statusUrl).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success
        _showSuccess('Connected to instance!');
        
        // Save Base URL
        // We use the same constructed clean baseUrl
        await AuthService().setBaseUrl(baseUrl);
        
        if (mounted) {
           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      } else {
        // Error from server
        _showError('Failed to connect. Status: ${response.statusCode}');
      }
    } catch (e) {
      // Connectivity Error
      _showError('Could not connect to server. Please check the URL and your connection.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'VitalGate',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(isDark ? 0.05 : 0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.dns,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Title
                    Text(
                      'Hostname Selection',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    Text(
                      'Enter the hostname of your self-hosted instance to begin syncing your health data securely.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: isDark ? AppColors.textMuted : const Color(0xFF475569),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Input Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Instance URL',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _hostController,
                          enabled: !_isLoading, 
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.go,
                          onSubmitted: (_) => _validateAndContinue(),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          decoration: InputDecoration(
                            hintText: 'https://your-instance.com',
                            hintStyle: TextStyle(
                              color: isDark ? AppColors.textMuted : Colors.grey.shade400,
                            ),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 16, right: 12),
                              child: Icon(
                                Icons.link,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                                size: 20,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 48),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 8),
                          child: Text(
                            'Must include https:// or http://',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _validateAndContinue,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: _isLoading 
                          ? LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.white,
                              size: 32,
                            )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                   const SizedBox(height: 24),
                   
                   InkWell(
                    onTap: () {}, // Link to docs
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book, 
                            size: 16,
                            color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Read setup documentation',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                   ),
                   const SizedBox(height: 8), // Bottom Safe Area space
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
