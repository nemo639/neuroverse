import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:neuroverse/features/auth/register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool showPassword = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  late AnimationController _floatingController;
  late AnimationController _pageController;
  
  String? emailError;
  String? passwordError;

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _pageController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      return false;
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => emailError = "Please enter a valid email");
      return false;
    }
    
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

  void _handleSignIn() {
    bool isEmailValid = _validateEmail(emailController.text);
    bool isPasswordValid = _validatePassword(passwordController.text);
    
    if (isEmailValid && isPasswordValid) {
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      body: Stack(
        children: [
          // Decorative Background Elements
          Positioned(
            top: -100,
            right: -50,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingController.value * 30),
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE0D4F7),
                    ),
                  ),
                );
              },
            ),
          ),
          
          Positioned(
            bottom: -80,
            left: -60,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_floatingController.value * 40),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFD4F1E8),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Welcome Header
                    _buildWelcomeHeader(),
                    
                    const SizedBox(height: 50),
                    
                    // Login Form
                    _buildLoginForm(),
                    
                    const SizedBox(height: 35),
                    
                    // Social Login
                    _buildSocialSection(),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return FadeTransition(
      opacity: _pageController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _pageController, curve: Curves.easeOut)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back 👋",
              style: TextStyle(
                fontSize: 32,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Sign in to continue",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _pageController,
        curve: Interval(0.2, 1.0),
      ),
      child: Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sign In",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 24),
            
            _buildInputField(
              label: "Email",
              hint: "your.email@example.com",
              icon: Icons.email_outlined,
              controller: emailController,
              errorText: emailError,
              onChanged: (value) {
                if (emailError != null) {
                  _validateEmail(value);
                }
              },
            ),
            
            SizedBox(height: 18),
            
            _buildInputField(
              label: "Password",
              hint: "Enter password",
              icon: Icons.lock_outline,
              controller: passwordController,
              isPassword: true,
              errorText: passwordError,
              onChanged: (value) {
                if (passwordError != null) {
                  _validatePassword(value);
                }
              },
            ),
            
            SizedBox(height: 12),
            
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Sign In Button
            Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _handleSignIn,
                  child: Center(
                    child: Text(
                      "Sign In",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
    bool isPassword = false,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorText != null 
                  ? Colors.red.withOpacity(0.5)
                  : Colors.black.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !showPassword,
            onChanged: onChanged,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.black26,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: errorText != null ? Colors.red.withOpacity(0.7) : Colors.black38,
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        showPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: Colors.black38,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          SizedBox(height: 6),
          Text(
            errorText,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSocialSection() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _pageController,
        curve: Interval(0.4, 1.0),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Divider(color: Colors.black12, thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Or continue with",
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.black12, thickness: 1)),
            ],
          ),
          
          SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIconButton(
                icon: Icons.g_mobiledata,
                backgroundColor: Colors.white,
                hasGradientIcon: true,
              ),
              SizedBox(width: 16),
              _buildSocialIconButton(
                icon: Icons.facebook,
                backgroundColor: Color(0xFF1877F2),
                iconColor: Colors.white,
              ),
              SizedBox(width: 16),
              _buildSocialIconButton(
                icon: Icons.apple,
                backgroundColor: Colors.black,
                iconColor: Colors.white,
              ),
            ],
          ),
          
          SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationThickness: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIconButton({
    required IconData icon,
    required Color backgroundColor,
    Color? iconColor,
    bool hasGradientIcon = false,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: backgroundColor == Colors.white
            ? Border.all(
                color: Colors.black.withOpacity(0.1),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () {},
          child: Center(
            child: hasGradientIcon
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4285F4),
                          Color(0xFFDB4437),
                          Color(0xFFF4B400),
                          Color(0xFF0F9D58),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text(
                        "G",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : Icon(icon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }
}