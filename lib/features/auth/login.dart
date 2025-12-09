import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuroverse/features/auth/register.dart';
import 'package:neuroverse/features/auth/forgot_password_screen.dart';
import 'package:neuroverse/core/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool showPassword = false;
  bool isLoading = false;
  bool rememberMe = false;
  
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  
  late AnimationController _floatingController;
  late AnimationController _pageController;
  late AnimationController _pulseController;
  
  String? emailError;
  String? passwordError;

  // Design colors
  static const Color bgColor = Color(0xFFF7F7F7);
  static const Color mintGreen = Color(0xFFB8E8D1);
  static const Color softLavender = Color(0xFFE8DFF0);
  static const Color creamBeige = Color(0xFFF5EBE0);
  static const Color darkCard = Color(0xFF1A1A1A);
  static const Color blueAccent = Color(0xFF3B82F6);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color greenAccent = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
    
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pageController.dispose();
    _pulseController.dispose();
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
  // Trim whitespace
  email = email.trim();
  
  if (email.isEmpty) {
    setState(() => emailError = "Email is required");
    return false;
  }
  
  // Length check (email addresses shouldn't be too long)
  if (email.length > 254) {
    setState(() => emailError = "Email is too long");
    return false;
  }
  
  // Must contain exactly one @
  if (email.split('@').length != 2) {
    setState(() => emailError = "Email must contain exactly one @");
    return false;
  }
  
  // Check for consecutive dots
  if (email.contains('..')) {
    setState(() => emailError = "Email cannot contain consecutive dots");
    return false;
  }
  
  // Check for dots at invalid positions
  if (email.startsWith('.') || email.endsWith('.')) {
    setState(() => emailError = "Email cannot start or end with a dot");
    return false;
  }
  
  // Check for dot before/after @
  if (email.contains('.@') || email.contains('@.')) {
    setState(() => emailError = "Invalid dot placement near @");
    return false;
  }
  
  // Check for spaces
  if (email.contains(' ')) {
    setState(() => emailError = "Email cannot contain spaces");
    return false;
  }
  
  // Split email into local and domain parts
  final parts = email.split('@');
  final localPart = parts[0];
  final domainPart = parts[1];
  
  // Local part validation (before @)
  if (localPart.isEmpty || localPart.length > 64) {
    setState(() => emailError = "Invalid email format");
    return false;
  }
  
  // Domain part validation (after @)
  if (domainPart.isEmpty || domainPart.length > 253) {
    setState(() => emailError = "Invalid domain");
    return false;
  }
  
  // Domain must contain at least one dot
  if (!domainPart.contains('.')) {
    setState(() => emailError = "Email must have a valid domain (e.g., .com)");
    return false;
  }
  
  // Check domain doesn't start or end with hyphen
  if (domainPart.startsWith('-') || domainPart.endsWith('-')) {
    setState(() => emailError = "Invalid domain format");
    return false;
  }
  
  // Main regex validation (RFC 5322 simplified but robust)
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );
  
  if (!emailRegex.hasMatch(email)) {
    setState(() => emailError = "Please enter a valid email address");
    return false;
  }
  
  // Check for valid TLD (at least 2 characters)
  final tld = domainPart.split('.').last;
  if (tld.length < 2) {
    setState(() => emailError = "Invalid domain extension");
    return false;
  }
  
  // All checks passed
  setState(() => emailError = null);
  return true;
}

  bool _validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => passwordError = "Password is required");
      return false;
    }
    
    if (password.length < 8) {
      setState(() => passwordError = "Password must be at least 8 characters");
      return false;
    }
    
    setState(() => passwordError = null);
    return true;
  }

  Future<void> _handleSignIn() async {
  HapticFeedback.mediumImpact();
  
  bool isEmailValid = _validateEmail(emailController.text.trim());
  bool isPasswordValid = _validatePassword(passwordController.text);
  
  if (isEmailValid && isPasswordValid) {
    setState(() => isLoading = true);
    
    // Call API
    final result = await ApiService.login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );
    
    setState(() => isLoading = false);
    
    if (mounted) {
      if (result['success']) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Login failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Animated Background Elements
          _buildAnimatedBackground(),
          
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 50),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    _buildWelcomeHeader(),
                    const SizedBox(height: 40),
                    _buildLoginForm(),
                    const SizedBox(height: 30),
                    _buildSocialSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Top right blob
        Positioned(
          top: -120,
          right: -80,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  math.sin(_floatingController.value * math.pi) * 20,
                  _floatingController.value * 40,
                ),
                child: Transform.rotate(
                  angle: _floatingController.value * 0.3,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          softLavender,
                          softLavender.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bottom left blob
        Positioned(
          bottom: -100,
          left: -80,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  -math.cos(_floatingController.value * math.pi) * 25,
                  -_floatingController.value * 50,
                ),
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        mintGreen,
                        mintGreen.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Center accent blob
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          right: -50,
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  math.sin(_floatingController.value * math.pi * 2) * 15,
                  math.cos(_floatingController.value * math.pi) * 20,
                ),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        creamBeige.withOpacity(0.8),
                        creamBeige.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return _buildAnimatedWidget(
      delay: 0.0,
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: darkCard,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: darkCard.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated pulse ring
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 60 + (_pulseController.value * 10),
                    height: 60 + (_pulseController.value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: mintGreen.withOpacity(0.3 - _pulseController.value * 0.2),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),
              // Brain icon
              CustomPaint(
                size: const Size(40, 40),
                painter: BrainLogoPainter(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return _buildAnimatedWidget(
      delay: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Welcome Back",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController.value * 0.1),
                    child: const Text(
                      "",
                      style: TextStyle(fontSize: 32),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Sign in to continue your brain health journey",
            style: TextStyle(
              fontSize: 15,
              color: Colors.black.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return _buildAnimatedWidget(
      delay: 0.2,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Field
            _buildInputField(
              label: "Email Address",
              hint: "your.email@example.com",
              icon: Icons.email_outlined,
              controller: emailController,
              focusNode: emailFocus,
              errorText: emailError,
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                if (emailError != null) _validateEmail(value);
              },
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(passwordFocus);
              },
            ),
            
            const SizedBox(height: 20),
            
            // Password Field
            _buildInputField(
              label: "Password",
              hint: "Enter your password",
              icon: Icons.lock_outline_rounded,
              controller: passwordController,
              focusNode: passwordFocus,
              isPassword: true,
              errorText: passwordError,
              onChanged: (value) {
                if (passwordError != null) _validatePassword(value);
              },
              onSubmitted: (_) => _handleSignIn(),
            ),
            
            const SizedBox(height: 16),
            
            // Remember Me & Forgot Password Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember Me
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => rememberMe = !rememberMe);
                  },
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: rememberMe ? darkCard : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: rememberMe ? darkCard : Colors.black.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: rememberMe
                            ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Remember me",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Forgot Password
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: blueAccent,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 28),
            
            // Sign In Button
            _buildSignInButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
    String? errorText,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null
                  ? Colors.red.withOpacity(0.5)
                  : focusNode.hasFocus
                      ? blueAccent.withOpacity(0.5)
                      : Colors.black.withOpacity(0.06),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: isPassword && !showPassword,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black.withOpacity(0.25),
                fontSize: 15,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  color: errorText != null
                      ? Colors.red.withOpacity(0.7)
                      : Colors.black.withOpacity(0.4),
                  size: 22,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              suffixIcon: isPassword
                  ? GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => showPassword = !showPassword);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 14),
                        child: Icon(
                          showPassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: Colors.black.withOpacity(0.4),
                          size: 22,
                        ),
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 6),
              Text(
                errorText,
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSignInButton() {
    return GestureDetector(
      onTap: isLoading ? null : _handleSignIn,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkCard,
              darkCard.withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: darkCard.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(mintGreen),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSocialSection() {
    return _buildAnimatedWidget(
      delay: 0.3,
      child: Column(
        children: [
          // Divider with text
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Or continue with",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.4),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Social Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                child: _buildGoogleLogo(),
                onTap: () => _handleSocialLogin('Google'),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                child: _buildAppleLogo(),
                backgroundColor: Colors.black,
                onTap: () => _handleSocialLogin('Apple'),
              ),
              const SizedBox(width: 16),
              _buildSocialButton(
                child: _buildFacebookLogo(),
                backgroundColor: const Color(0xFF1877F2),
                onTap: () => _handleSocialLogin('Facebook'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Sign Up Link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: darkCard,
                        width: 2,
                      ),
                    ),
                  ),
                  child: const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required Widget child,
    Color backgroundColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: backgroundColor == Colors.white
              ? Border.all(color: Colors.black.withOpacity(0.08), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: backgroundColor == Colors.white
                  ? Colors.black.withOpacity(0.06)
                  : backgroundColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildGoogleLogo() {
    return CustomPaint(
      size: const Size(24, 24),
      painter: GoogleLogoPainter(),
    );
  }

  Widget _buildAppleLogo() {
    return const Icon(
      Icons.apple_rounded,
      color: Colors.white,
      size: 28,
    );
  }

  Widget _buildFacebookLogo() {
    return const Text(
      'f',
      style: TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        fontFamily: 'Arial',
      ),
    );
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Continue with $provider',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildAnimatedWidget({required double delay, required Widget child}) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _pageController,
        curve: Interval(delay, math.min(delay + 0.4, 1.0), curve: Curves.easeOut),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _pageController,
          curve: Interval(delay, math.min(delay + 0.4, 1.0), curve: Curves.easeOut),
        )),
        child: child,
      ),
    );
  }
}

// Custom Painters for Logos
class BrainLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8E8D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Left hemisphere
    final leftPath = Path();
    leftPath.moveTo(center.dx - 2, center.dy - 12);
    leftPath.quadraticBezierTo(center.dx - 14, center.dy - 10, center.dx - 12, center.dy);
    leftPath.quadraticBezierTo(center.dx - 16, center.dy + 5, center.dx - 10, center.dy + 12);
    leftPath.quadraticBezierTo(center.dx - 4, center.dy + 16, center.dx - 2, center.dy + 12);
    
    // Right hemisphere
    final rightPath = Path();
    rightPath.moveTo(center.dx + 2, center.dy - 12);
    rightPath.quadraticBezierTo(center.dx + 14, center.dy - 10, center.dx + 12, center.dy);
    rightPath.quadraticBezierTo(center.dx + 16, center.dy + 5, center.dx + 10, center.dy + 12);
    rightPath.quadraticBezierTo(center.dx + 4, center.dy + 16, center.dx + 2, center.dy + 12);
    
    canvas.drawPath(leftPath, paint);
    canvas.drawPath(rightPath, paint);
    
    // Center line
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      paint..strokeWidth = 1.5,
    );
    
    // Neural connections
    paint.strokeWidth = 1.5;
    canvas.drawLine(Offset(center.dx - 8, center.dy - 4), Offset(center.dx - 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx + 8, center.dy - 4), Offset(center.dx + 4, center.dy), paint);
    canvas.drawLine(Offset(center.dx - 6, center.dy + 6), Offset(center.dx - 2, center.dy + 4), paint);
    canvas.drawLine(Offset(center.dx + 6, center.dy + 6), Offset(center.dx + 2, center.dy + 4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Blue arc (top right)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 4,
      -math.pi / 2,
      false,
      bluePaint,
    );
    
    // Green arc (bottom right)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi / 4,
      math.pi / 2,
      false,
      greenPaint,
    );
    
    // Yellow arc (bottom left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi * 3 / 4,
      math.pi / 2,
      false,
      yellowPaint,
    );
    
    // Red arc (top left)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi * 3 / 4,
      -math.pi / 2,
      false,
      redPaint,
    );
    
    // Blue horizontal line
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(center.dx + radius - 2, center.dy),
      bluePaint..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}