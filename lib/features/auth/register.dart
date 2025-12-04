import 'dart:ui';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool agreeToTerms = false;
  
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  late AnimationController _floatingController;
  late AnimationController _pageController;
  
  String? nameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  
  String? passwordStrengthText;
  Color? passwordStrengthColor;

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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateName(String name) {
    if (name.isEmpty) {
      setState(() => nameError = "Name is required");
      return false;
    }
    
    if (name.length < 3) {
      setState(() => nameError = "Name must be at least 3 characters");
      return false;
    }
    
    setState(() => nameError = null);
    return true;
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => emailError = "Email is required");
      return false;
    }
    
    // Fixed: Changed ):$ to )$ in regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(email)) {
      setState(() => emailError = "Please enter a valid email");
      return false;
    }
    
    setState(() => emailError = null);
    return true;
  }

  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        passwordStrengthText = null;
        passwordStrengthColor = null;
      });
      return;
    }

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    bool hasMinLength = password.length >= 8;

    int strength = 0;
    if (hasMinLength) strength++;
    if (hasUppercase) strength++;
    if (hasLowercase) strength++;
    if (hasDigits) strength++;
    if (hasSpecialCharacters) strength++;

    if (strength <= 2) {
      setState(() {
        passwordStrengthText = "Weak password";
        passwordStrengthColor = Colors.red;
      });
    } else if (strength == 3) {
      setState(() {
        passwordStrengthText = "Medium password";
        passwordStrengthColor = Colors.orange;
      });
    } else {
      setState(() {
        passwordStrengthText = "Strong password";
        passwordStrengthColor = Colors.green;
      });
    }
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

  bool _validateConfirmPassword(String confirmPassword) {
    if (confirmPassword.isEmpty) {
      setState(() => confirmPasswordError = "Please confirm your password");
      return false;
    }
    
    if (confirmPassword != passwordController.text) {
      setState(() => confirmPasswordError = "Passwords do not match");
      return false;
    }
    
    setState(() => confirmPasswordError = null);
    return true;
  }

  void _handleSignUp() {
    bool isNameValid = _validateName(nameController.text);
    bool isEmailValid = _validateEmail(emailController.text);
    bool isPasswordValid = _validatePassword(passwordController.text);
    bool isConfirmPasswordValid = _validateConfirmPassword(confirmPasswordController.text);
    
    if (!agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please agree to the Terms & Conditions'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    if (isNameValid && isEmailValid && isPasswordValid && isConfirmPasswordValid) {
      // Navigate to home screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            constraints: BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Terms & Conditions",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTermsSection(
                          "1. Data Collection & Privacy",
                          "NeuroVerse collects neurological assessment data including speech, motor, cognitive test results, and digital wellness metrics. All data is encrypted and stored securely. Your data will be used solely for health screening and may be anonymized for research purposes.",
                        ),
                        _buildTermsSection(
                          "2. Medical Disclaimer",
                          "This app provides AI-powered screening results and is NOT a substitute for professional medical diagnosis. Always consult with qualified healthcare professionals for medical advice.",
                        ),
                        _buildTermsSection(
                          "3. User Responsibilities",
                          "You agree to provide accurate information and use the app responsibly. Do not share your account credentials with others.",
                        ),
                        _buildTermsSection(
                          "4. Research Contribution",
                          "Anonymized data may be used to improve AI models and contribute to neurodegenerative disease research. You can opt out in settings.",
                        ),
                        _buildTermsSection(
                          "5. Limitation of Liability",
                          "NeuroVerse is provided 'as is' without warranties. We are not liable for any decisions made based on app results.",
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.pop(context),
                      child: Center(
                        child: Text(
                          "I Understand",
                          style: TextStyle(
                            color: Colors.white,
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
          ),
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
                    const SizedBox(height: 20),
                    
                    // Back Button
                    _buildBackButton(),
                    
                    const SizedBox(height: 20),
                    
                    // Welcome Header
                    _buildWelcomeHeader(),
                    
                    const SizedBox(height: 40),
                    
                    // Sign Up Form
                    _buildSignUpForm(),
                    
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

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black87,
          size: 18,
        ),
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
              "Create Account",
              style: TextStyle(
                fontSize: 32,
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Start your brain health journey",
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

  Widget _buildSignUpForm() {
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
              "Sign Up",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 24),
            
            _buildInputField(
              label: "Full Name",
              hint: "John Doe",
              icon: Icons.person_outline,
              controller: nameController,
              errorText: nameError,
              onChanged: (value) {
                if (nameError != null) {
                  _validateName(value);
                }
              },
            ),
            
            SizedBox(height: 18),
            
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
              hint: "Create password",
              icon: Icons.lock_outline,
              controller: passwordController,
              isPassword: true,
              showPassword: showPassword,
              errorText: passwordError,
              strengthText: passwordStrengthText,
              strengthColor: passwordStrengthColor,
              onTogglePassword: () {
                setState(() => showPassword = !showPassword);
              },
              onChanged: (value) {
                _checkPasswordStrength(value);
                if (passwordError != null) {
                  _validatePassword(value);
                }
              },
            ),
            
            SizedBox(height: 18),
            
            _buildInputField(
              label: "Confirm Password",
              hint: "Confirm password",
              icon: Icons.lock_outline,
              controller: confirmPasswordController,
              isPassword: true,
              showPassword: showConfirmPassword,
              errorText: confirmPasswordError,
              onTogglePassword: () {
                setState(() => showConfirmPassword = !showConfirmPassword);
              },
              onChanged: (value) {
                if (confirmPasswordError != null) {
                  _validateConfirmPassword(value);
                }
              },
            ),
            
            SizedBox(height: 20),
            
            // Terms and Conditions Checkbox
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: agreeToTerms,
                    onChanged: (value) {
                      setState(() => agreeToTerms = value ?? false);
                    },
                    activeColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsDialog,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms & Conditions",
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Sign Up Button
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
                  onTap: _handleSignUp,
                  child: Center(
                    child: Text(
                      "Create Account",
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
    bool showPassword = false,
    VoidCallback? onTogglePassword,
    String? errorText,
    String? strengthText,
    Color? strengthColor,
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
                      onPressed: onTogglePassword,
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
        if (strengthText != null && errorText == null) ...[
          SizedBox(height: 6),
          Text(
            strengthText,
            style: TextStyle(
              color: strengthColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
                  "Or sign up with",
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
                "Already have an account? ",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Sign In",
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