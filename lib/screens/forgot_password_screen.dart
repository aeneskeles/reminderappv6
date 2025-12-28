import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.resetPassword(_emailController.text.trim());
        
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Color>(
      future: ThemeService.instance.getThemeColor(),
      builder: (context, snapshot) {
        final themeColor = snapshot.data ?? ThemeService.instance.defaultColor;
        final gradientColors = ThemeService.instance.getGradientColors(themeColor);
        
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // Blurred background shapes
                  Positioned(
                    top: -100,
                    left: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    right: -100,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  // Main content
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 60),
                            // Glassmorphism card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(32.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Icon
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: themeColor,
                                        ),
                                        child: const Icon(
                                          Icons.lock_reset,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // Title
                                      Text(
                                        _emailSent ? 'E-posta Gönderildi!' : 'Şifremi Unuttum',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _emailSent
                                            ? 'E-posta adresinize şifre sıfırlama bağlantısı gönderildi. Lütfen e-postanızı kontrol edin.'
                                            : 'E-posta adresinize şifre sıfırlama bağlantısı göndereceğiz.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                      if (!_emailSent) ...[
                                        const SizedBox(height: 32),
                                        // Email alanı
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'E-posta',
                                            labelStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            hintText: 'E-posta adresinizi girin',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email,
                                              color: Colors.white.withOpacity(0.7),
                                            ),
                                            filled: true,
                                            fillColor: Colors.white.withOpacity(0.3),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide.none,
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: BorderSide(
                                                color: Colors.white.withOpacity(0.3),
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(15),
                                              borderSide: const BorderSide(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'E-posta adresi gereklidir';
                                            }
                                            if (!value.contains('@')) {
                                              return 'Geçerli bir e-posta adresi girin';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 24),
                                        // Gönder butonu
                                        Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                gradientColors[0],
                                                gradientColors[1],
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(15),
                                            boxShadow: [
                                              BoxShadow(
                                                color: gradientColors[0].withOpacity(0.4),
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isLoading ? null : _sendResetEmail,
                                              borderRadius: BorderRadius.circular(15),
                                              child: Center(
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        ),
                                                      )
                                                    : const Text(
                                                        'Şifre Sıfırlama Bağlantısı Gönder',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      // Geri dön linki
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'Giriş ekranına dön',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

